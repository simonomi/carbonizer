import BinaryParser

enum RunLength {
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
		let endIndex = inputData.endIndex.advanced(by: -2)
		var lastEndIndex = inputData.startIndex
		while index < endIndex {
			guard inputData[index..<index.advanced(by: 3)].isAllTheSame() else {
				index += 1
				continue
			}
			
			let uncompressedBytes = inputData[lastEndIndex..<index]
			for index in stride(from: uncompressedBytes.startIndex, to: uncompressedBytes.endIndex, by: maxUncompressedCount) {
				let endIndex = min(index + maxUncompressedCount, uncompressedBytes.endIndex)
				let smallerUncompressedBytes = uncompressedBytes[index..<endIndex]
				let uncompressedFlag = Flag(uncompressedByteCount: smallerUncompressedBytes.count)
				uncompressedFlag.write(to: outputData)
				outputData.write(uncompressedBytes)
			}
			
			let compressedBytes = inputData[index...].prefix { $0 == inputData[index] }
			for index in stride(from: compressedBytes.startIndex, to: compressedBytes.endIndex, by: maxCompressedCount) {
				let endIndex = min(index + maxCompressedCount, compressedBytes.endIndex)
				let smallerCompressedBytes = compressedBytes[index..<endIndex]
				let compressedFlag = Flag(compressedByteCount: smallerCompressedBytes.count)
				compressedFlag.write(to: outputData)
				outputData.write(smallerCompressedBytes[index])
			}
			
			index = compressedBytes.endIndex
			lastEndIndex = index
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
	
	static let maxCompressedCount = Int(Byte.max) / 2 + 3
	static let maxUncompressedCount = Int(Byte.max) / 2 + 1
	
	struct Flag {
		var raw: Byte
		
		private static let compressionBit: Byte = 0b1000_0000
		
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
			raw >> 7 != 0
//			raw & Self.compressionBit != 0
		}
		
		var byteCount: Int {
			if isCompressed {
				Int(raw & 0b0111_1111 + 3)
			} else {
				Int(raw & 0b0111_1111 + 1)
			}
		}
		
		func write(to data: Datawriter) {
			data.write(raw)
		}
	}
}
