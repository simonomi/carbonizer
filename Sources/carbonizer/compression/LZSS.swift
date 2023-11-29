//
//  LZSS.swift
//
//
//  Created by alice on 2023-11-28.
//

import BinaryParser

enum LZSS {
	static func compress(_ data: Datastream) -> Datastream {
		fatalError("TODO:")
	}
	
//	static func decompress2(_ inputData: Datastream) throws -> Datastream {
//		let header = try inputData.read(CompressionHeader.self)
//		assert(header.type == .lzss)
//		
//		let outputData = Datawriter(capacity: Int(header.decompressedSize))
//		
//		while outputData.offset < header.decompressedSize {
//			let flag = try Flag(from: inputData)
//			
//			for blockType in flag.nextBlockTypes {
//				switch blockType {
//					case .uncompressed:
//						outputData.write(try inputData.read(UInt8.self))
//					case .compressed:
//						let blockData = try inputData.read(UInt16.self)
//						
//						let length = Int(blockData) >> 4 & 0b1111 + 3
//						let displacement = Int((blockData & 0b1111) << 8 | blockData >> 8 + 1)
//						
//						for _ in 0..<length {
//							outputData.write(outputData.bytes[outputData.offset - displacement])
//						}
//				}
//				
//				if outputData.offset >= header.decompressedSize {
//					break
//				}
//			}
//		}
//		
//		return outputData.intoDatastream()
//	}
	
	static func decompress(_ inputData: Datastream) throws -> Datastream {
		let header = try inputData.read(CompressionHeader.self)
		assert(header.type == .lzss)
		
		var inputData = inputData.bytes[inputData.offset...]
		
		var outputData = [UInt8]()
		outputData.reserveCapacity(Int(header.decompressedSize))
		
		var flagBit = 7
		var flag: UInt8!
		
		while outputData.count < header.decompressedSize {
			if flagBit == 7 {
				flag = inputData.removeFirst()
			}
			
			if flag >> flagBit & 1 == 0 {
				// uncompressed
				outputData.append(inputData.removeFirst())
			} else {
				// compressed
				let blockData = UInt16(inputData.removeFirst()) | UInt16(inputData.removeFirst()) << 8
				
				// disp- length -lacement
				// 1111   0000    1111
				let length = Int(blockData) >> 4 & 0b1111 + 3
				let displacement = Int((blockData & 0b1111) << 8 | blockData >> 8 + 1)
				
				for _ in 0..<length {
					outputData.append(outputData[outputData.count - displacement])
				}
			}
			
			if flagBit == 0 {
				flagBit = 7
			} else {
				flagBit -= 1
			}
		}
		
		return Datastream(outputData)
	}
	
//	struct Flag {
//		var nextBlockTypes: [BlockType]
//		
//		enum BlockType: UInt8 {
//			case uncompressed, compressed
//		}
//		
//		init(from data: Datastream) throws {
//			let flagData = try data.read(UInt8.self)
//			
//			nextBlockTypes = (1...8).map {
//				BlockType(rawValue: (flagData >> (8 - $0)) & 1)!
//			}
//		}
//	}
}
