//
//  RunLength.swift
//
//
//  Created by simon pellerin on 2023-06-19.
//

import Foundation

enum RunLength {
	static func compress(_ data: Data) throws -> Data {
		let outputData = Datawriter()
		
		let header = CompressionHeader(type: .runLength, decompressedSize: UInt32(data.count))
		header.write(to: outputData)
		
		var index = data.startIndex
		let endIndex = data.endIndex.advanced(by: -2)
		var lastEndIndex = data.startIndex
		while index < endIndex {
			guard data[index ..< index.advanced(by: 3)].isAllTheSame() else {
				index += 1
				continue
			}
			
			let uncompressedBytes = data[lastEndIndex ..< index]
			let maxUncompressedLength = Int(UInt8.max) / 2 + 1
			for index in stride(from: uncompressedBytes.startIndex, to: uncompressedBytes.endIndex, by: maxUncompressedLength) {
				let endIndex = min(index + maxUncompressedLength, uncompressedBytes.endIndex)
				let smallerUncompressedBytes = uncompressedBytes[index ..< endIndex]
				let uncompressedFlag = Flag(type: .uncompressed, length: UInt8(smallerUncompressedBytes.count - 1))
				uncompressedFlag.write(to: outputData)
				outputData.write(uncompressedBytes)
			}
			
			var compressedBytes = data[index...].prefix { $0 == data[index] }
			let maxCompressedLength = Int(UInt8.max) / 2 + 3
			for index in stride(from: compressedBytes.startIndex, to: compressedBytes.endIndex, by: maxCompressedLength) {
				let endIndex = min(index + maxCompressedLength, compressedBytes.endIndex)
				let smallerCompressedBytes = compressedBytes[index ..< endIndex]
				
				if smallerCompressedBytes.count < 3 {
					compressedBytes = compressedBytes.dropLast(smallerCompressedBytes.count)
					break
				}
				
				let compressedFlag = Flag(type: .compressed, length: UInt8(smallerCompressedBytes.count - 3))
				compressedFlag.write(to: outputData)
				outputData.write(smallerCompressedBytes[index])
			}
			
			index = compressedBytes.endIndex
			lastEndIndex = index
		}
		
		outputData.fourByteAlign()
		
		return outputData.data
	}
	
	static func decompress(_ data: Data) throws -> Data {
		let inputData = Datastream(data)
		let outputData = Datawriter()
		
		let header = try CompressionHeader(from: inputData)
		
		while outputData.offset < header.decompressedSize {
			let flag = try Flag(from: inputData)
			switch flag.type {
				case .uncompressed:
					outputData.write(try inputData.read(flag.length))
				case .compressed:
					outputData.write(Data(repeating: try inputData.read(UInt8.self), count: Int(flag.length)))
			}
		}
		
		return outputData.data
	}
	
	struct Flag {
		var type: FlagType
		var length: UInt8
		
		enum FlagType {
			case uncompressed, compressed
		}
		
		init(type: FlagType, length: UInt8) {
			self.type = type
			self.length = length
		}
		
		init(from data: Datastream) throws {
			let flagData = try data.read(UInt8.self)
			
			let typeBit = flagData & 0b10000000
			if typeBit == 0 {
				type = .uncompressed
				length = flagData & 0b01111111 + 1
			} else {
				type = .compressed
				length = flagData & 0b01111111 + 3
			}
		}
		
		func write(to data: Datawriter) {
			let typeBit = type == .uncompressed ? UInt8.zero : 0b10000000
			data.write(typeBit | length)
		}
	}
}
