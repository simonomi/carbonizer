extension Huffman {
	struct DecompressionNode {
		var nodeData: Byte
		
		func leftOffset(currentOffset: Int) -> Int {
			let offset = Int(nodeData) & 0b111111 + 1
			return dropLowestBit(of: currentOffset) + 2 * offset
		}
		
		var leftIsData: Bool {
			nodeData >> 7 & 1 != 0
		}
		
		func rightOffset(currentOffset: Int) -> Int {
			let offset = Int(nodeData) & 0b111111 + 1
			return dropLowestBit(of: currentOffset) + 2 * offset + 1
		}
		
		var rightIsData: Bool {
			nodeData >> 6 & 1 != 0
		}
	}
}

fileprivate func dropLowestBit<T: FixedWidthInteger>(of number: T) -> T {
	number & ~1
}
