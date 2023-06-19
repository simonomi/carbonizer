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
		
		let header = Header(reserved: 0, type: 3, decompressedSize: UInt32(data.count))
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
			
			let compressedBytes = data[index...].prefix { $0 == data[index] }
			let maxCompressedLength = Int(UInt8.max) / 2 + 3
			for index in stride(from: compressedBytes.startIndex, to: compressedBytes.endIndex, by: maxCompressedLength) {
				let endIndex = min(index + maxCompressedLength, compressedBytes.endIndex)
				let smallerCompressedBytes = compressedBytes[index ..< endIndex]
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
		
		let header = try Header(from: inputData)
		
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
	
	struct Header {
		var reserved: UInt8 // 4 bits
		var type: UInt8 // 4 bits, should be 3 for run-length
		var decompressedSize: UInt32 // 24 bits
		
		init(reserved: UInt8, type: UInt8, decompressedSize: UInt32) {
			self.reserved = reserved
			self.type = type
			self.decompressedSize = decompressedSize
		}
		
		init(from data: Datastream) throws {
			let headerData = try data.read(UInt32.self)
			
			reserved = UInt8(headerData & 0b1111)
			type = UInt8((headerData >> 4) & 0b1111)
			decompressedSize = headerData >> 8
		}
		
		func write(to data: Datawriter) {
			let headerData = UInt32(reserved) | UInt32(type << 4) | (decompressedSize << 8)
			data.write(headerData)
		}
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
