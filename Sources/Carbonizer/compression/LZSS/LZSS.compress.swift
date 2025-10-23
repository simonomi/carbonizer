import BinaryParser

extension LZSS {
	static func compress(_ inputData: Datastream) -> Datastream {
		let inputData = inputData.bytes[inputData.offset...]
		let outputData = Datawriter()
		
		let header = CompressionHeader(
			dataSize: 0,
			type: .lzss,
			decompressedSize: UInt32(inputData.count)
		)
		header.write(to: outputData)
		
		var inputOffset = inputData.startIndex
		
	mainloop:
		while true {
			let flagIndex = outputData.bytes.endIndex
			outputData.write(UInt8(0))
			
			for flagBit in (0..<8).reversed() {
				if let compressedString = inputData.longestCompressedString(at: inputOffset) {
					outputData.bytes[flagIndex] |= 1 << flagBit
					compressedString.write(to: outputData)
					inputOffset += compressedString.count
				} else {
					outputData.write(inputData[inputOffset])
					inputOffset += 1
				}
				
				guard inputData.indices.contains(inputOffset) else {
					break mainloop
				}
			}
		}
		
		outputData.fourByteAlign()
		
		return outputData.intoDatastream()
	}
}

fileprivate extension Collection<UInt8> where Index == Int, Indices == Range<Index> {
	// TODO: this is slow (at least in debug mode)... can it be improved?
	func longestCompressedString(at index: Index) -> LZSS.CompressedString? {
		let goal = self[index...]
		
		// are there enough bytes left to encode a string?
		guard goal.count >= LZSS.minCompressedCount else { return nil }
		
		let startIndex = index - LZSS.maxDisplacement
		let endIndex = index - LZSS.minDisplacement
		let range = (startIndex..<endIndex).clamped(to: indices)
		
		let possibleStartIndices = self[range]
			.indices(of: self[index])
			.ranges
			.flatMap { $0 }
			.reversed()
		
		var bestString: LZSS.CompressedString?
		
		for matchStartIndex in possibleStartIndices {
			let match = self[matchStartIndex...].commonPrefix(with: goal)
			
			guard match.count > bestString?.count ?? (LZSS.minCompressedCount - 1) else { continue }
			
			let displacement = index - matchStartIndex
			
			if match.count >= LZSS.maxCompressedCount {
				return LZSS.CompressedString(
					count: LZSS.maxCompressedCount,
					displacement: displacement
				)
			} else {
				bestString = LZSS.CompressedString(
					count: match.count,
					displacement: displacement
				)
			}
		}
		
		return bestString
	}
}
