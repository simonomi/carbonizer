import BinaryParser
import Foundation

import Darwin.C // TODO: remove

struct MCM {
	var compression: (CompressionType, CompressionType)
	var maxChunkSize: UInt32
	
	var content: any FileData
	
	enum CompressionType: UInt8 {
		case none, runLength, lzss, huffman
		
		var compress: (Datastream) -> Datastream {
			switch self {
				case .none:                identity
				case .runLength: RunLength.compress
				case .lzss:           LZSS.compress
				case .huffman:     Huffman.compress
			}
		}
		
		var decompress: (Datastream) throws -> Datastream {
			switch self {
				case .none:                identity
				case .runLength: RunLength.decompress
				case .lzss:           LZSS.decompress
				case .huffman:     Huffman.decompress
			}
		}
	}
	
	@BinaryConvertible
	struct Binary {
		var magicBytes = "MCM"
		var decompressedSize: UInt32
		var maxChunkSize: UInt32
		var chunkCount: UInt32
		var compressionType1: UInt8
		var compressionType2: UInt8
		@Padding(bytes: 2)
		@Count(givenBy: \Self.chunkCount)
		var chunkOffsets: [UInt32]
		var endOfFileOffset: UInt32
		@Offsets(givenBy: \Self.chunkOffsets)
		@EndOffset(givenBy: \Self.endOfFileOffset)
		var chunks: [Datastream]
	}
}

// MARK: packed
extension MCM {
	enum DecompressionError: Error {
		case whileReading(Any.Type, (CompressionType, CompressionType), any Error)
	}
	
	init(_ binary: Binary) throws {
		compression = (
			CompressionType(rawValue: binary.compressionType1) ?? .none,
			CompressionType(rawValue: binary.compressionType2) ?? .none
		)
		maxChunkSize = binary.maxChunkSize
		
		print(".", terminator: "")
		fflush(stdout)
		
		do {
			content = try createFileData(
                binary.chunks
					.map(compression.0.decompress)
					.map(compression.1.decompress)
					.joined()
			)
		} catch {
			throw DecompressionError.whileReading(MCM.self, compression, error)
		}
	}
}

extension MCM.Binary {
	init(_ mcm: MCM) {
		maxChunkSize = mcm.maxChunkSize
		// TODO: turn back on once compression is implemented
//		compressionType1 = mcm.compression.0.rawValue
//		compressionType2 = mcm.compression.1.rawValue
		compressionType1 = 0
		compressionType2 = 0
		
		let data = Datawriter()
		mcm.content.packed().write(to: data)
		
		decompressedSize = UInt32(data.offset)
		
		chunks = data
			.intoDatastream()
			.chunked(maxSize: Int(maxChunkSize))
//			.map(mcm.compression.1.compress)
//			.map(mcm.compression.0.compress)
		
		chunkCount = UInt32(chunks.count)
		
		chunkOffsets = createOffsets(
			start: 24 + chunkCount * 4,
			sizes: chunks.map(\.bytes.count).map(UInt32.init)
		)
		
		if let lastChunkOffset = chunkOffsets.last,
		   let lastChunkSize = (chunks.last?.bytes.count).map(UInt32.init) {
			endOfFileOffset = lastChunkOffset + lastChunkSize
		} else {
			endOfFileOffset = 24
		}
	}
}

// MARK: unpacked
extension MCM {
	enum NoMetadataError: Error {
//        case noMetadata(File)
	}
	
	init(_ file: File) throws {
		guard let metadata = file.metadata else {
            fatalError("TODO:")
//			throw NoMetadataError.noMetadata(file)
		}
		
		compression = metadata.compression
		maxChunkSize = metadata.maxChunkSize
		content = file.data
	}
}

extension File {
	init(index: Int, mcm: MCM) {
		name = String(index).padded(toLength: 4, with: "0")
		metadata = Metadata(
			standalone: false,
			compression: mcm.compression,
			maxChunkSize: mcm.maxChunkSize,
			index: UInt16(index)
		)
		data = mcm.content
	}
    
    init(name: String, standalone mcm: MCM) {
        self.name = name
        metadata = Metadata(
            standalone: true,
            compression: mcm.compression,
            maxChunkSize: mcm.maxChunkSize,
            index: 0
        )
        data = mcm.content
    }
}
