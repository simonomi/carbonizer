import BinaryParser

extension Huffman {
	// what the actual fucking algorithm did they use to make this tree
	// this *works* but only matches for 16-symbol trees (i think?)
	static func makeTree(
		inputData: ByteSlice,
		dataSize: UInt8
	) -> CompressionNode {
		if dataSize == 4 {
			var symbols = inputData
				.reduce(into: [:]) { partialResult, byte in
					partialResult[byte, default: 0] += 1
				}
				.map { CompressionNode.symbol($0, frequency: $1) }
				.sorted()
			
			var branches: [CompressionNode] = []
			
			while symbols.count + branches.count > 1 {
				func lowestFrequencyNode() -> CompressionNode? {
					switch (symbols.first, branches.first) {
						case (let firstSymbol?, let firstBranch?):
							if firstSymbol.frequency < firstBranch.frequency {
								symbols.removeFirst()
							} else {
								branches.removeFirst()
							}
						case (.some, nil):
							symbols.removeFirst()
						case (nil, .some):
							branches.removeFirst()
						case (nil, nil):
							nil
					}
				}
				
				var right = lowestFrequencyNode()!
				var left = lowestFrequencyNode()!
				
				// TODO: write a better comment here
				// so, go right -> left in order of frequency
				// UNLESS only one is a symbol, in which case
				// it goes on the left
				if right.isData, !left.isData {
					swap(&left, &right)
				}
				
				branches.append(.branch(left: left, right: right))
			}
			
			return branches.first ?? symbols.first!
		} else {
//			var nodes = inputData
//				.reduce(into: [:]) { partialResult, byte in
//					partialResult[byte, default: 0] += 1
//				}
//				.sorted(by: \.key)
//				.map { CompressionNode.symbol($0, frequency: $1) }
//
//			let leafCount = nodes.count
//			while nodes.count < (leafCount * 2 - 1) {
//				var leftNode: CompressionNode? = nil
//				var rightNode: CompressionNode? = nil
//
//				for node in nodes {
//					// skip nodes with parents
//					if nodes.contains(where: { $0.hasChild(node) }) { continue }
//
//					if leftNode == nil || node.frequency < leftNode!.frequency {
//						rightNode = leftNode
//						leftNode = node
//					} else if rightNode == nil || node.frequency < rightNode!.frequency {
//						rightNode = node
//					}
//				}
//
//				nodes.append(.branch(left: leftNode!, right: rightNode!))
//			}
//
//			tree = nodes.last!
//
//			// WHAT THE FUCK ALGORITHM??????????
//
//			todo()
			
			var symbols = inputData
				.reduce(into: [:]) { partialResult, byte in
					partialResult[byte, default: 0] += 1
				}
				.map { CompressionNode.symbol($0, frequency: $1) }
				.sorted()
			
			var branches: [CompressionNode] = []
			
			while symbols.count + branches.count > 1 {
				func lowestFrequencyNode() -> CompressionNode? {
					switch (symbols.first, branches.first) {
						case (let firstSymbol?, let firstBranch?):
							if firstSymbol.frequency < firstBranch.frequency {
								symbols.removeFirst()
							} else {
								branches.removeFirst()
							}
						case (.some, nil):
							symbols.removeFirst()
						case (nil, .some):
							branches.removeFirst()
						case (nil, nil):
							nil
					}
				}
				
				var right = lowestFrequencyNode()!
				var left = lowestFrequencyNode()!
				
				// TODO: write a better comment here
				// so, go right -> left in order of frequency
				// UNLESS only one is a symbol, in which case
				// it goes on the left
				if right.isData, !left.isData {
					swap(&left, &right)
				}
				
				branches.append(.branch(left: left, right: right))
			}
			
			return branches.first ?? symbols.first!
		}
	}
}
