import BinaryParser
import Foundation

struct MAR {
    var name: String
	var files: [MCM]
	
	@BinaryConvertible
	struct Binary {
        @Include
		static let magicBytes = "MAR"
		var fileCount: UInt32
		@Count(givenBy: \Self.fileCount)
		var indexes: [Index]
		@Offsets(givenBy: \Self.indexes, at: \.fileOffset)
		var files: [MCM.Binary]
		
		@BinaryConvertible
		struct Index {
			var fileOffset: UInt32
			var decompressedSize: UInt32
		}
	}
}


extension MAR: FileSystemObject {
    func savePath(in directory: URL) -> URL {
        Folder(name: name, contents: [])
            .savePath(in: directory)
    }
    
    func write(into directory: URL) throws {
        if files.count == 1,
           let file = files.first
        {
            try File(name: name, standalone: file)
                .write(into: directory)
            
        } else {
            try Folder(
                name: name + ".mar",
                contents: files.enumerated().map(File.init)
            ).write(into: directory)
        }
    }
    
    func packed() -> PackedMAR {
        PackedMAR(
            name: name,
            binary: MAR.Binary(self)
        )
    }
    
    func unpacked() throws -> Self { self }
}

struct PackedMAR: FileSystemObject {
    var name: String
    var binary: MAR.Binary
    
    func savePath(in directory: URL) -> URL {
        directory.appending(component: name)
    }
    
    func write(into directory: URL) throws {
        let writer = Datawriter()
        writer.write(binary)
        
        try File(
            name: name,
            data: writer.intoDatastream()
        )
        .write(into: directory)
    }
    
    func packed() -> Self { self }
    
//    func unpacked() throws -> MAR {
//        try MAR(name: name, binary: binary)
//    }
    
    // disable mar decompression
    func unpacked() throws -> Self { self }
}


// MARK: packed
extension MAR {
	static let fileExtension = "mar"
	
    init(name: String, binary: Binary) throws {
        print("\n" + name, terminator: "")
        self.name = name
		files = try binary.files.map(MCM.init)
	}
}

extension MAR.Binary {
	init(_ mar: MAR) {
		fileCount = UInt32(mar.files.count)
		
		files = mar.files.map(MCM.Binary.init)
		
		let firstFileIndex = 8 + fileCount * 8
		let mcmSizes = files.map(\.endOfFileOffset)
		let offsets = createOffsets(start: firstFileIndex, sizes: mcmSizes)
		
		let decompressedSizes = files.map(\.decompressedSize)
		
		indexes = zip(offsets, decompressedSizes).map(Index.init)
	}
}

// MARK: unpacked
//extension MAR {
//	init(unpacked: [any FileSystemObject]) throws {
//		files = try unpacked.compactMap(as: File.self).map(MCM.init)
//	}
//	
//	func toUnpacked() -> [any FileSystemObject] {
//		files.enumerated().map(File.init)
//	}
//}
