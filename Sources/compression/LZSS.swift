//
//  LZSS.swift
//
//
//  Created by simon pellerin on 2023-06-19.
//

import Foundation

enum LZSS {
	static func compress(_ data: Data) throws -> Data {
		fatalError("cannot compress lzss")
	}
	
	static func decompress(_ data: Data) throws -> Data {
		let inputData = Datastream(data)
		let outputData = Datawriter()
		
		let header = try CompressionHeader(from: inputData)
		
		while outputData.offset < header.decompressedSize {
			let flag = try Flag(from: inputData)
			
			for blockType in flag.nextBlockTypes {
				switch blockType {
					case .uncompressed:
						outputData.write(try inputData.read(UInt8.self))
					case .compressed:
						let blockData = try inputData.read(UInt16.self)
						
						let copyCount = (blockData >> 4) & 0b1111 + 3
						let displacement = ((blockData & 0b1111) << 8) | (blockData >> 8) + 1
						
						(0..<copyCount).forEach { _ in
							outputData.write(outputData.data[outputData.offset - Int(displacement)])
						}
				}
				
				if outputData.offset >= header.decompressedSize {
					break
				}
			}
		}
		
		return outputData.data
	}
	
	struct Flag {
		var nextBlockTypes: [BlockType]
		
		enum BlockType: UInt8 {
			case uncompressed, compressed
		}
		
		init(from data: Datastream) throws {
			let flagData = try data.read(UInt8.self)
			
			nextBlockTypes = (0..<8).reversed().map {
				BlockType(rawValue: (flagData >> $0) & 1)!
			}
		}
	}
}
