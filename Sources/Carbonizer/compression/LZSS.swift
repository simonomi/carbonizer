import BinaryParser

enum LZSS {
	static let minCompressedCount = 3
	static let maxCompressedCount = 0b1111 + minCompressedCount
	static let minDisplacement = 1
	static let maxDisplacement = 0b1111_1111_1111 + minDisplacement
	
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
			outputData.write(Byte(0))
			
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
		
		return Datastream(outputData.bytes)
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
	
	struct CompressedString {
		// count displacement
		//  0000_1111_1111_1111
		var firstByte: Byte
		var secondByte: Byte
		
		init(_ firstByte: Byte, _ secondByte: Byte) {
			self.firstByte = firstByte
			self.secondByte = secondByte
		}
		
		init(count: Int, displacement: Int) {
			precondition((minCompressedCount...maxCompressedCount).contains(count), "invalid count: \(count)")
			precondition((minDisplacement...maxDisplacement).contains(displacement), "invalid displacement: \(displacement)")
			
			let count = Byte(count - minCompressedCount)
			
			let displacement = displacement - minDisplacement
			let disp = Byte(displacement >> 8)
			let lacement = Byte(displacement & 0b1111_1111)
			
			firstByte = (count << 4) | disp
			secondByte = lacement
		}
		
		var count: Int {
			Int(firstByte >> 4) + minCompressedCount
		}
		
		var displacement: Int {
			Int(firstByte & 0b1111) << 8 | Int(secondByte) + minDisplacement
		}
		
		func write(to data: Datawriter) {
			data.write(firstByte)
			data.write(secondByte)
		}
	}
}

fileprivate extension Collection<Byte> where Index == Int, Indices == Range<Index> {
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
