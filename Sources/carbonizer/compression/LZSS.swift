import BinaryParser

enum LZSS {
	static func compress(_ data: Datastream) -> Datastream {
		fatalError("TODO:")
	}
	
	static func decompress(_ inputData: Datastream) throws -> Datastream {
		let header = try inputData.read(CompressionHeader.self)
		precondition(header.type == .lzss)
		precondition(header.decompressedSize > 0)

		let inputData = inputData.bytes[inputData.offset...]
		var inputOffset = inputData.startIndex
		
		var outputData = [UInt8]()
		outputData.reserveCapacity(Int(header.decompressedSize))
		
	mainloop:
		while true {
			let flag = inputData[inputOffset]
			inputOffset += 1
			
			for flagBit in (0..<8).reversed() {
				if flag >> flagBit & 1 == 0 {
					// uncompressed
					outputData.append(inputData[inputOffset])
					inputOffset += 1
				} else {
					// compressed
					let lowBlockByte = inputData[inputOffset]
					let highBlockByte = inputData[inputOffset + 1]
					inputOffset += 2
					
					// -lacement length disp-
					//  11111111  0000  1111
					let length = lowBlockByte >> 4 + 3
					let displacement = Int(lowBlockByte & 0b1111) << 8 | Int(highBlockByte) + 1
					
					for _ in 0..<length {
						outputData.append(outputData[outputData.count - displacement])
					}
				}
				
				guard outputData.count < header.decompressedSize else {
					break mainloop
				}
			}
		}
		
		return Datastream(outputData)
	}
}
