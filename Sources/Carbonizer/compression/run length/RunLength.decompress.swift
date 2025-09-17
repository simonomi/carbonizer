import BinaryParser

extension RunLength {
	static func decompress(_ inputData: Datastream) throws -> Datastream {
		let header = try inputData.read(CompressionHeader.self)
		precondition(header.type == .runLength)
		
		let inputData = inputData.bytes[inputData.offset...]
		var inputOffset = inputData.startIndex
		
		var outputData = [Byte]()
		outputData.reserveCapacity(Int(header.decompressedSize))
		
		while outputData.count < header.decompressedSize {
			let flag = Flag(inputData[inputOffset])
			inputOffset += 1
			
			if flag.isCompressed {
				let byte = inputData[inputOffset]
				inputOffset += 1
				
				outputData.append(contentsOf: repeatElement(byte, count: flag.byteCount))
			} else {
				let inputRange = Range(start: inputOffset, count: flag.byteCount)
				inputOffset += flag.byteCount
				
				outputData.append(contentsOf: inputData[inputRange])
			}
		}
		
		return Datastream(outputData)
	}
}
