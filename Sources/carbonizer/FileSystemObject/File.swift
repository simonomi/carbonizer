import Foundation
import BinaryParser

struct File {
    var name: String
    var metadata: Metadata?
    var data: any FileData
    
    struct Metadata {
        var standalone: Bool // 1 bit
        var compression: (MCM.CompressionType, MCM.CompressionType) // 2 bits, 2 bits
        var maxChunkSize: UInt32 // 4 bits, then multiplied by 4kB
        var index: UInt16 // 16 bits
        
        init(standalone: Bool, compression: (MCM.CompressionType, MCM.CompressionType), maxChunkSize: UInt32, index: UInt16) {
            self.standalone = standalone
            self.compression = compression
            self.maxChunkSize = maxChunkSize
            self.index = index
        }
        
        init?(_ date: Date) {
            let data = Int(date.timeIntervalSince1970)
            
            let twentyFiveBitLimit = 33554432
            guard data < twentyFiveBitLimit else { return nil }
            
            let standaloneBit = data & 1
            let compression1Bits = data >> 1 & 0b11
            let compression2Bits = data >> 3 & 0b11
            let maxChunkSizeBits = data >> 5 & 0b1111
            let indexBits = data >> 9
            
            standalone = standaloneBit > 0
            
            compression = (
                MCM.CompressionType(rawValue: UInt8(compression1Bits)) ?? .none,
                MCM.CompressionType(rawValue: UInt8(compression2Bits)) ?? .none
            )
            
            maxChunkSize = UInt32(maxChunkSizeBits) * 0x1000
            
            index = UInt16(indexBits)
        }
        
        var asDate: Date {
            let standaloneBit = standalone ? 1 : UInt32.zero
            let compression1Bits = UInt32(compression.0.rawValue)
            let compression2Bits = UInt32(compression.1.rawValue)
            let maxChunkSizeBits = maxChunkSize / 0x1000
            let indexBits = UInt32(index)
            
            let outputBits = standaloneBit | compression1Bits << 1 | compression2Bits << 3 | maxChunkSizeBits << 5 | indexBits << 9
            return Date(timeIntervalSince1970: TimeInterval(outputBits))
        }
        
        func swizzled(_ body: (inout Self) -> Void) -> Self {
            var mutableSelf = self
            body(&mutableSelf)
            return mutableSelf
        }
    }
}

func createFile(contentsOf path: URL) throws -> any FileSystemObject {
    let fileExtension = path.pathExtension
    let name = path.deletingPathExtension().lastPathComponent
    let data = Datastream(try Data(contentsOf: path))
    
    let metadata = try path
        .getCreationDate()
        .flatMap(File.Metadata.init)
    
    let file = try createFile(name: name, fileExtension: fileExtension, data: data)
    
    if let metadata, var file = file as? File {
        file.metadata = metadata
        return MAR(
            name: name,
            files: [try MCM(file)]
        )
    } else {
        return file
    }
}

// file extension
func createFile(name: String, fileExtension: String, data: Datastream) throws -> any FileSystemObject {
    switch fileExtension {
        case PackedNDS.fileExtension:
            PackedNDS(
                name: name,
                binary: try data.read(NDS.Binary.self)
            )
        default:
            try createFile(name: name, data: data)
    }
}

// magic bytes - FileSystemObject
func createFile(name: String, data: Datastream) throws -> any FileSystemObject {
    let marker = data.placeMarker()
    let magicBytes = (try? data.read(String.self, length: 3)) ?? ""
    data.jump(to: marker)
    
//    print(URL(filePath: name).pathExtension) // bin, csv, ica, sdat
    
    return switch magicBytes {
        case MAR.Binary.magicBytes:
            PackedMAR(
                name: name,
                binary: try data.read(MAR.Binary.self)
            )
        default:
            File(
                name: name,
                data: try createFileData(data)
            )
    }
}

// magic bytes - FileData
func createFileData(_ data: Datastream) throws -> any FileData {
    let marker = data.placeMarker()
    let magicBytes = (try? data.read(String.self, length: 3)) ?? ""
    data.jump(to: marker)
    
    return switch magicBytes {
        case DMG.Binary.magicBytes:
            try data.read(DMG.Binary.self)
        default:
            data
    }
}

extension File: FileSystemObject {
    func savePath(in directory: URL) -> URL {
        directory
            .appending(component: name)
            .appendingPathExtension(type(of: data).fileExtension)
    }
    
    func write(into directory: URL) throws {
        let writer = Datawriter()
        data.write(to: writer)
        let filePath = savePath(in: directory)
        
        do {
            try Data(writer.bytes).write(to: filePath)
        } catch {
            throw BinaryParserError.whileWriting(type(of: data), error)
        }
        
        if let metadataDate = metadata?.asDate {
            do {
                try filePath.setCreationDate(to: metadataDate)
            } catch {
                throw BinaryParserError.whileWriting(Metadata.self, error)
            }
        }
    }
    
    func packed() -> Self {
        File(
            name: name,
            metadata: metadata,
            data: data.packed()
        )
    }
    
    func unpacked() throws -> Self {
        File(
            name: name,
            metadata: metadata,
            data: data.unpacked()
        )
    }
}
