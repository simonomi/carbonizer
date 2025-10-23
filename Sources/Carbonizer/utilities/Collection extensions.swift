extension Collection {
	var isNotEmpty: Bool {
		!isEmpty
	}
}

extension Collection where Index: Strideable {
	public func chunked(maxSize: Index.Stride) -> [SubSequence] {
		stride(from: startIndex, to: endIndex, by: maxSize).map {
			self[$0..<Swift.min($0.advanced(by: maxSize), endIndex)]
		}
	}
	
	public func chunked(exactSize: Index.Stride) -> [SubSequence] {
		chunks(exactSize: exactSize, every: exactSize)
	}
	
//	public func chunks(maxSize: Int, every: Int)
	
	public func chunks(
		exactSize: Index.Stride,
		every chunkInterval: Index.Stride
	) -> [SubSequence] {
		stride(
			from: startIndex,
			through: endIndex.advanced(by: -exactSize),
			by: chunkInterval
		).map {
			self[$0..<$0.advanced(by: exactSize)]
		}
	}
}

extension Collection where Element: Equatable {
	func areAllTheSame() -> Bool {
		allSatisfy { $0 == first }
	}
	
	func commonPrefix(with other: some Collection<Element>) -> SubSequence {
		zip(indices, other.indices)
			.first { self[$0] != other[$1] }
			.map(\.0)
			.map { self[..<$0] } ?? self[..<Swift.min(endIndex, index(startIndex, offsetBy: other.count))]
	}
}

extension Collection<UInt8> {
	func firstRunIndices(minCount: Int) -> Range<Index>? {
		for index in indices.dropLast(minCount - 1) {
			let window = self[index..<self.index(index, offsetBy: minCount)]
			if window.areAllTheSame() {
				let endOfRun = self[index...].firstIndex { $0 != self[index] } ?? endIndex
				
				return index..<endOfRun
			}
		}
		
		return nil
	}
}
