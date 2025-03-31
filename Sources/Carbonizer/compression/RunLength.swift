import BinaryParser

enum RunLength {
	static func compress(_ data: Datastream) -> Datastream {
		todo()
	}
	
	static func decompress(_ inputData: Datastream) throws -> Datastream {
		let header = try inputData.read(CompressionHeader.self)
		precondition(header.type == .runLength)
		
		let inputData = inputData.bytes[inputData.offset...]
		var inputOffset = inputData.startIndex
		
		var outputData = [UInt8]()
		outputData.reserveCapacity(Int(header.decompressedSize))
		
		while outputData.count < header.decompressedSize {
			let flag = Flag(inputData[inputOffset])
			inputOffset += 1
			
			switch flag {
				case .uncompressed(let length):
					let inputRange = Range(start: inputOffset, count: length)
					inputOffset += length
					
					outputData.append(contentsOf: inputData[inputRange])
				case .compressed(let length):
					let byte = inputData[inputOffset]
					inputOffset += 1
					
					outputData.append(contentsOf: Array(repeating: byte, count: length))
			}
		}
		
		return Datastream(outputData)
	}
	
	enum Flag {
		case compressed(Int), uncompressed(Int)
		
		init(_ byte: UInt8) {
			self = if byte >> 7 == 0 {
				.uncompressed(Int(byte & 0b01111111 + 1))
			} else {
				.compressed(Int(byte & 0b01111111 + 3))
			}
		}
	}
}
