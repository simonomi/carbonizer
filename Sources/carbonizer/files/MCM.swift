//
//  MCM.swift
//
//
//  Created by alice on 2023-11-25.
//

import BinaryParser
import Foundation

struct MCM {
	var compression: (CompressionType, CompressionType)
	var maxChunkSize: UInt32
	
	// TODO: should be generated, not cached ?
	// what if file is modified before being reloaded
	var compressedSize: UInt32
	var decompressedSize: UInt32
	
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
		
//		@Offset(givenBy: \Self.chunkOffsets.first!)
//		@EndOffset(givenBy: \Self.endOfFileOffset)
//		var chunks: Datastream
	}
}

// MARK: packed
extension MCM {
	enum DecompressionError: Error {
		case whileReading(Any.Type, (CompressionType, CompressionType), any Error)
	}
	
	init(packed: Binary) throws {
		compression = (
			CompressionType(rawValue: packed.compressionType1) ?? .none,
			CompressionType(rawValue: packed.compressionType2) ?? .none
		)
		maxChunkSize = packed.maxChunkSize
		
		decompressedSize = packed.decompressedSize
		compressedSize = packed.compressedSize
		
		do {
			content = try createFileData(
				name: "",
				extension: "",
				data: packed.chunks
					.map(compression.0.decompress)
					.map(compression.1.decompress)
					.joined()
			)
			
//			if decompressedSize == 10072 {
//				let start = Date.now
//				content = try packed.chunks
//					.map(compression.0.decompress)
//					.map(compression.1.decompress)
//					.joined()
//				print(-start.timeIntervalSinceNow)
//			}
			
			content = Datastream([])
		} catch {
			throw DecompressionError.whileReading(MCM.self, compression, error)
		}
	}
}

extension MCM.Binary {
	var compressedSize: UInt32 {
		guard let firstOffset = chunkOffsets.first else { return 0 }
		return endOfFileOffset - firstOffset
	}
}

extension MCM.Binary {
	init(_ mcm: MCM) {
		decompressedSize = mcm.decompressedSize
		maxChunkSize = mcm.maxChunkSize
//		chunkCount =
		compressionType1 = mcm.compression.0.rawValue
		compressionType2 = mcm.compression.1.rawValue
//		chunkOffsets = createOffsets(
//			start: 16 + chunkCount * 4,
//			sizes:
//		)
//		endOfFileOffset =
//		chunks =
		fatalError("TODO:")
	}
}

// MARK: unpacked
extension MCM {
	init(unpacked: File) {
		guard let metadata = unpacked.metadata else {
			fatalError("TODO:")
		}
		
		compression = metadata.compression
		maxChunkSize = metadata.maxChunkSize
//		compressedSize =
//		decompressedSize =
		content = unpacked.data
		
		fatalError("TODO:")
	}
}

extension File {
	init(index: Int, mcm: MCM) {
		name = String(index).padded(toLength: 4, with: "0")
		fileExtension = ""
		metadata = Metadata(
			standalone: false,
			compression: mcm.compression,
			maxChunkSize: mcm.maxChunkSize,
			index: UInt16(index)
		)
		data = mcm.content
	}
}
