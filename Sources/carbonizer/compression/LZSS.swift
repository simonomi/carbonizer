import BinaryParser

enum LZSS {
	static func compress(_ data: Datastream) -> Datastream {
		fatalError("TODO:")
	}
	
	static func decompress(_ inputData: Datastream) throws -> Datastream {
		let header = try inputData.read(CompressionHeader.self)
		assert(header.type == .lzss)
		
		let inputData = inputData.bytes[inputData.offset...]
		var inputOffset = inputData.startIndex
		
		var outputData = [UInt8]()
		outputData.reserveCapacity(Int(header.decompressedSize))
		
		var flagBit = 7
		var flag: UInt8!
		
		while outputData.count < header.decompressedSize {
			if flagBit == 7 {
				flag = inputData[inputOffset]
				inputOffset += 1
			}
			
			if flag >> flagBit & 1 == 0 {
				// uncompressed
				outputData.append(inputData[inputOffset])
				inputOffset += 1
			} else {
				// compressed
				let blockData = UInt16(inputData[inputOffset]) | 
								UInt16(inputData[inputOffset + 1]) << 8
				inputOffset += 2
				
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
}
