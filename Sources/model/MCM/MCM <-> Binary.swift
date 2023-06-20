//
//  MCM <-> Binary.swift
//
//
//  Created by simon pellerin on 2023-06-18.
//

import Foundation

extension MCMFile {
	init(index: Int, data inputData: Data) throws {
		self.index = index
		
		let data = Datastream(inputData)
		
		data.seek(to: 8)
		
		let maxChunkSize = try data.read(UInt32.self)
		self.maxChunkSize = maxChunkSize
		
		let numberOfChunks = try data.read(UInt32.self)
		
		compression = try (CompressionType(from: data), CompressionType(from: data))
		
		data.seek(bytes: 2)
		
		let chunkOffsets = try (0..<numberOfChunks).map { _ in
			try data.read(UInt32.self)
		}
		let endOfFile = try data.read(UInt32.self)
		let chunkEndOffsets = chunkOffsets.dropFirst() + [endOfFile]
		
		content = try File(
			named: String(index),
			from: Data(
				try zip(chunkOffsets, chunkEndOffsets)
					.map {
						data.seek(to: $0)
						return try data.read(to: $1)
					}
					.map(compression.0.decompress)
					.map(compression.1.decompress)
					.joined()
			)
		)
	}
}

extension MCMFile.CompressionType {
	init(from data: Datastream) throws {
		self = Self(rawValue: try data.read(UInt8.self)) ?? .none
	}
	
	func write(to data: Datawriter) {
		data.write(rawValue)
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

extension Data {
	init(from mcmFile: MCMFile) throws {
		let data = Datawriter()
		
		try data.write("MCM\0")
		
		let uncompressedData = try Data(from: mcmFile.content)
		
		data.write(UInt32(uncompressedData.count))
		
		data.write(mcmFile.maxChunkSize)
		
		let numberOfChunks = UInt32((Double(uncompressedData.count) / Double(mcmFile.maxChunkSize)).rounded(.up))
		data.write(numberOfChunks)
		
		mcmFile.compression.0.write(to: data)
		mcmFile.compression.1.write(to: data)

		data.fourByteAlign()
		
		let chunkedData = try uncompressedData
			.chunked(into: Int(mcmFile.maxChunkSize))
			.map(mcmFile.compression.1.compress)
			.map(mcmFile.compression.0.compress)
		
		var currentChunkOffset = UInt32(data.offset + 4 * (chunkedData.count + 1))
		data.write(currentChunkOffset)
		chunkedData.forEach {
			currentChunkOffset += UInt32($0.count)
			data.write(currentChunkOffset)
		}
		
		chunkedData.forEach {
			data.write($0)
		}
		
		self = data.data
		// TODO: maybe 4-byte align?
	}
}
