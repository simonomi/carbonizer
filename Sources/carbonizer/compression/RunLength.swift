//
//  RunLength.swift
//
//
//  Created by alice on 2023-11-28.
//

import BinaryParser

enum RunLength {
	static func compress(_ data: Datastream) -> Datastream {
		fatalError("TODO:")
	}
	
//	static func decompress(_ inputData: Datastream) throws -> Datastream {
//		let header = try inputData.read(CompressionHeader.self)
//		assert(header.type == .runLength)
//		
//		let outputData = Datawriter(capacity: Int(header.decompressedSize))
//		
//		while outputData.offset < header.decompressedSize {
//			let flag = try inputData.read(Flag.self)
//			switch flag.type {
//				case .uncompressed:
//					outputData.write(try inputData.read([UInt8].self, count: flag.length))
//				case .compressed:
//					let byte = try inputData.read(UInt8.self)
//					for _ in 0..<flag.length {
//						outputData.write(byte)
//					}
//			}
//		}
//		
//		return outputData.intoDatastream()
//	}
	
	static func decompress(_ inputData: Datastream) throws -> Datastream {
		let header = try inputData.read(CompressionHeader.self)
		assert(header.type == .runLength)
		
		var inputData = inputData.bytes[inputData.offset...]
		
		var outputData = [UInt8]()
		outputData.reserveCapacity(Int(header.decompressedSize))
		
		while outputData.count < header.decompressedSize {
			let flag = inputData.removeFirst()
			
			if flag >> 7 == 0 {
				// uncompressed
				let length = flag & 0b01111111 + 1
				for _ in 0..<length {
					outputData.append(inputData.removeFirst())
				}
			} else {
				// compressed
				let length = flag & 0b01111111 + 3
				let byte = inputData.removeFirst()
				for _ in 0..<length {
					outputData.append(byte)
				}
			}
		}
		
		return Datastream(outputData)
	}
	
//	@BinaryConvertible
//	struct Flag {
//		var flagData: UInt8
//		
//		var type: FlagType {
//			FlagType(rawValue: flagData >> 7)!
//		}
//		
//		var length: UInt8 {
//			switch type {
//				case .uncompressed: flagData & 0b01111111 + 1
//				case .compressed:   flagData & 0b01111111 + 3
//			}
//		}
//		
//		enum FlagType: UInt8 {
//			case uncompressed, compressed
//		}
//		
////		init(type: FlagType, length: UInt8) {
////			data = type.rawValue << 7 | length // TODO: -1? -3?
////		}
//	}
}
