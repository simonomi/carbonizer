import BinaryParser

extension RunLength {
	static func compress(_ inputData: Datastream) -> Datastream {
		let inputData = inputData.bytes[inputData.offset...]
		let outputData = Datawriter()
		
		let header = CompressionHeader(
			dataSize: 0,
			type: .runLength,
			decompressedSize: UInt32(inputData.count)
		)
		header.write(to: outputData)
		
		var inputOffset = inputData.startIndex
		while let runIndices = inputData[inputOffset...].firstRunIndices(minCount: 3) {
			let uncompressedBytes = inputData[inputOffset..<runIndices.lowerBound]
			
			for chunk in uncompressedBytes.chunked(maxSize: maxUncompressedCount) {
				Flag(uncompressedByteCount: chunk.count).write(to: outputData)
				outputData.write(chunk)
			}
			
			let compressedBytes = inputData[runIndices]
			
			for chunk in compressedBytes.chunked(maxSize: maxCompressedCount) {
				Flag(compressedByteCount: chunk.count).write(to: outputData)
				outputData.write(chunk.first!)
			}
			
			inputOffset = runIndices.endIndex
		}
		
		if inputOffset != inputData.endIndex {
			let uncompressedBytes = inputData[inputOffset...]
			
			for chunk in uncompressedBytes.chunked(maxSize: maxUncompressedCount) {
				Flag(uncompressedByteCount: chunk.count).write(to: outputData)
				outputData.write(chunk)
			}
		}
		
		outputData.fourByteAlign()
		
		return outputData.intoDatastream()
	}
}
