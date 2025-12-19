import BinaryParser

extension LZSS {
	static func decompress(_ inputData: consuming Datastream) throws -> Datastream {
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
				if (flag >> flagBit) & 1 == 0 {
					// uncompressed
					outputData.append(inputData[inputOffset])
					inputOffset += 1
				} else {
					// compressed
					let compressedString = CompressedString(
						inputData[inputOffset],
						inputData[inputOffset + 1]
					)
					inputOffset += 2
					
					for _ in 0..<compressedString.count {
						outputData.append(outputData[outputData.endIndex - compressedString.displacement])
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
