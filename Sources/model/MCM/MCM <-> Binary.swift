//
//  MCM <-> Binary.swift
//
//
//  Created by simon pellerin on 2023-06-18.
//

import Foundation

extension MCMFile {
	init(from binaryFile: BinaryFile) throws {
		name = binaryFile.name + ".mcm"
		
		let data = Datastream(binaryFile.contents)
		
		data.seek(to: 8)
		
		maxChunkSize = try data.read(UInt32.self)
		
		let numberOfChunks = try data.read(UInt32.self)
		
		compression = try (CompressionType(from: data), CompressionType(from: data))
		
		data.seek(bytes: 2)
		
		let chunkOffsets = try (0..<numberOfChunks).map { _ in
			try data.read(UInt32.self)
		}
		data.seek(bytes: 4)
		
		content = Data()
		content = Data(
			try chunkOffsets
				.map {
					data.seek(to: $0)
					return try data.read(to: min($0 + maxChunkSize, UInt32(data.data.count)))
				}
				.map(compression.0.decompress)
				.map(compression.1.decompress)
				.joined()
		)
	}
}

extension MCMFile.CompressionType {
	init(from data: Datastream) throws {
		switch try data.read(UInt8.self) {
			case 1:
				self = .runLengthEncoding
			case 2:
				self = .lzss
			case 3:
				self = .huffman
			default:
				self = .none
		}
	}
	
	func compress(_ data: Data) throws -> Data {
		switch self {
			case .none:
				return data
			case .runLengthEncoding:
				return try RunLength.compress(data)
			case .lzss:
				return try LZSS.compress(data)
			case .huffman:
				return try Huffman.compress(data)
		}
	}
	
	func decompress(_ data: Data) throws -> Data {
		switch self {
			case .none:
				return data
			case .runLengthEncoding:
				return try RunLength.decompress(data)
			case .lzss:
				return try LZSS.decompress(data)
			case .huffman:
				return try Huffman.decompress(data)
		}
	}
}

//extension BinaryFile {
//	init(from mcmFile: MCMFile) throws {
//		
//	}
//}
