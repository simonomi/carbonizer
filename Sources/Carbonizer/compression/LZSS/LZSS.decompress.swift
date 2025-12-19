import BinaryParser

extension LZSS {
	static func decompress(_ inputData: consuming ByteSlice) throws -> ByteSlice {
		var data = Datastream(copy inputData)
		let header = try data.read(CompressionHeader.self)
		precondition(header.type == .lzss)
		precondition(header.decompressedSize > 0)
		
		var inputOffset = inputData.startIndex + 4
		
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
		
		return outputData[...]
	}
}
