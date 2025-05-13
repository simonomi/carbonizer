import BinaryParser

enum RunLength {
	static let maxCompressedCount = Int(Byte.max) / 2 + 3
	static let maxUncompressedCount = Int(Byte.max) / 2 + 1
	
	static func compress(_ inputData: Datastream) -> Datastream {
		let inputData = inputData.bytes[inputData.offset...]
		let outputData = Datawriter()
		
		let header = CompressionHeader(
			dataSize: 0,
			type: .runLength,
			decompressedSize: UInt32(inputData.count)
		)
		header.write(to: outputData)
		
		var index = inputData.startIndex
		while let runIndices = inputData[index...].firstRunIndices(minCount: 3) {
			let uncompressedBytes = inputData[index..<runIndices.lowerBound]
			
			for chunk in uncompressedBytes.chunked(maxSize: maxUncompressedCount) {
				Flag(uncompressedByteCount: chunk.count).write(to: outputData)
				outputData.write(chunk)
			}
			
			let compressedBytes = inputData[runIndices]
			
			for chunk in compressedBytes.chunked(maxSize: maxCompressedCount) {
				Flag(compressedByteCount: chunk.count).write(to: outputData)
				outputData.write(chunk.first!)
			}
			
			index = runIndices.endIndex
		}
		
		if index != inputData.endIndex {
			let uncompressedBytes = inputData[index...]
			
			for chunk in uncompressedBytes.chunked(maxSize: maxUncompressedCount) {
				Flag(uncompressedByteCount: chunk.count).write(to: outputData)
				outputData.write(chunk)
			}
		}
		
		outputData.fourByteAlign()
		
		return Datastream(outputData.bytes)
	}
	
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
	
	struct Flag {
		var raw: Byte
		
		private static let compressionBit: Byte = 0b1000_0000
		private static let byteCountMask: Byte = ~compressionBit
		
		init(_ raw: Byte) {
			self.raw = raw
		}
		
		// TODO: should these have 'Count' in the name??
		init(compressedByteCount: Int) {
			raw = Self.compressionBit | Byte(compressedByteCount - 3)
		}
		
		init(uncompressedByteCount: Int) {
			raw = Byte(uncompressedByteCount - 1)
			precondition(!isCompressed, "tried to encode more than the maximum number of uncompressed bytes: \(uncompressedByteCount) (max \(maxUncompressedCount))")
		}
		
		var isCompressed: Bool {
			raw & Self.compressionBit != 0
		}
		
		var byteCount: Int {
			if isCompressed {
				Int(raw & Self.byteCountMask) + 3
			} else {
				Int(raw & Self.byteCountMask) + 1
			}
		}
		
		func write(to data: Datawriter) {
			data.write(raw)
		}
	}
}
