import BinaryParser

enum RunLength {
	static func compress(_ data: Datastream) -> Datastream {
		fatalError("TODO:")
	}
	
	static func decompress(_ inputData: Datastream) throws -> Datastream {
		let header = try inputData.read(CompressionHeader.self)
		assert(header.type == .runLength)
		
		let inputData = inputData.bytes[inputData.offset...]
		var inputOffset = inputData.startIndex
		
		var outputData = [UInt8]()
		outputData.reserveCapacity(Int(header.decompressedSize))
		
		while outputData.count < header.decompressedSize {
			let flag = inputData[inputOffset]
			inputOffset += 1
			
			if flag >> 7 == 0 {
				// uncompressed
				let length = flag & 0b01111111 + 1
				for _ in 0..<length {
					outputData.append(inputData[inputOffset])
					inputOffset += 1
				}
			} else {
				// compressed
				let byte = inputData[inputOffset]
				inputOffset += 1
				
				let length = flag & 0b01111111 + 3
				for _ in 0..<length {
					outputData.append(byte)
				}
			}
		}
		
		return Datastream(outputData)
	}
}
