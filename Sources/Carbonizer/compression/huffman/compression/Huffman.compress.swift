import BinaryParser

extension Huffman {
	static func compress(_ inputData: Datastream, info: CompressionInfo?) -> Datastream {
		todo()
	}
	
	// this is a prototype version that somewhat works with certain files (4-bit compression)
	// but still fails horribly with others (8-bit). im not sure how on earth the 8-bit
	// huffman trees are generated. if i ever figure that out, implement it here, in addition to
	// deciding which data size to use. until then, i'm going to change metadata to include
	// a way to store the huffman tree/data size for recompression.
	//
	// ideally all we'd need to store is data size, which would still fit in the creation date,
	// but to fit the entire tree, metadata will need to be its own file. having its own file is
	// also just a nice feature to have for reliability (and linux systems), so let's do it!
//	static func compress(_ inputData: Datastream, info: CompressionInfo?) -> Datastream {
//		let originalInputData = inputData.bytes[inputData.offset...]
//		let outputData = Datawriter()
//
////		let uniqueByteCount = Set(originalInputData).count
//
//		// note: map should be 8
//		// either when 8 or when map, builds the tree wrong :/
//
//		// TODO: how is data size determined....?
//		// oh god is it based on how well its compressed??
//		// add a flag in metadata for this?
//		// theory: based on the number of unique bytes? whats the max?
//		// - nope, both 4-bit and 8-bit have 0-256 unique bytes
//		//  - or does it depend on the *shape* of the tree... grrrr
//
//		// TODO: is defaulting to 8 the right behavior? probably not
//		let dataSize = info?.dataSize ?? 8
//		precondition(dataSize == 4 || dataSize == 8, "huffman data size must be 4 or 8")
//
//		let header = CompressionHeader(
//			dataSize: dataSize,
//			type: .huffman,
//			decompressedSize: UInt32(originalInputData.count)
//		)
//		header.write(to: outputData)
//
//		guard originalInputData.isNotEmpty else { return outputData.intoDatastream() }
//
//		let inputData = if header.dataSize == 4 {
//			originalInputData.flatMap { [$0 & 0b1111, $0 >> 4] }[...]
//		} else {
//			originalInputData
//		}
//
//		// what the actual fucking algorithm did they use to make this tree
//
//		// MARK: create tree
//
//		let tree: CompressionNode
//
//		if let givenTree = info?.tree {
//			tree = CompressionNode(givenTree)
//		} else if header.dataSize == 4 {
//			var symbols = inputData
//				.reduce(into: [:]) { partialResult, byte in
//					partialResult[byte, default: 0] += 1
//				}
//				.map { CompressionNode.symbol($0, frequency: $1) }
//				.sorted()
//
//			var branches: [CompressionNode] = []
//
//			while symbols.count + branches.count > 1 {
//				func lowestFrequencyNode() -> CompressionNode? {
//					switch (symbols.first, branches.first) {
//						case (let firstSymbol?, let firstBranch?):
//							if firstSymbol.frequency < firstBranch.frequency {
//								symbols.removeFirst()
//							} else {
//								branches.removeFirst()
//							}
//						case (.some, nil):
//							symbols.removeFirst()
//						case (nil, .some):
//							branches.removeFirst()
//						case (nil, nil):
//							nil
//					}
//				}
//
//				var right = lowestFrequencyNode()!
//				var left = lowestFrequencyNode()!
//
//				// TODO: write a better comment here
//				// so, go right -> left in order of frequency
//				// UNLESS only one is a symbol, in which case
//				// it goes on the left
//				if right.isData, !left.isData {
//					swap(&left, &right)
//				}
//
//				branches.append(.branch(left: left, right: right))
//			}
//
//			tree = branches.first ?? symbols.first!
//		} else {
////			var nodes = inputData
////				.reduce(into: [:]) { partialResult, byte in
////					partialResult[byte, default: 0] += 1
////				}
////				.sorted(by: \.key)
////				.map { CompressionNode.symbol($0, frequency: $1) }
////
////			let leafCount = nodes.count
////			while nodes.count < (leafCount * 2 - 1) {
////				var leftNode: CompressionNode? = nil
////				var rightNode: CompressionNode? = nil
////
////				for node in nodes {
////					// skip nodes with parents
////					if nodes.contains(where: { $0.hasChild(node) }) { continue }
////
////					if leftNode == nil || node.frequency < leftNode!.frequency {
////						rightNode = leftNode
////						leftNode = node
////					} else if rightNode == nil || node.frequency < rightNode!.frequency {
////						rightNode = node
////					}
////				}
////
////				nodes.append(.branch(left: leftNode!, right: rightNode!))
////			}
////
////			tree = nodes.last!
//
//
//			// WHAT THE FUCK ALGORITHM??????????
//
////			todo()
//
//			var symbols = inputData
//				.reduce(into: [:]) { partialResult, byte in
//					partialResult[byte, default: 0] += 1
//				}
//				.map { CompressionNode.symbol($0, frequency: $1) }
//				.sorted()
//
//			var branches: [CompressionNode] = []
//
//			while symbols.count + branches.count > 1 {
//				func lowestFrequencyNode() -> CompressionNode? {
//					switch (symbols.first, branches.first) {
//						case (let firstSymbol?, let firstBranch?):
//							if firstSymbol.frequency < firstBranch.frequency {
//								symbols.removeFirst()
//							} else {
//								branches.removeFirst()
//							}
//						case (.some, nil):
//							symbols.removeFirst()
//						case (nil, .some):
//							branches.removeFirst()
//						case (nil, nil):
//							nil
//					}
//				}
//
//				var right = lowestFrequencyNode()!
//				var left = lowestFrequencyNode()!
//
//				// TODO: write a better comment here
//				// so, go right -> left in order of frequency
//				// UNLESS only one is a symbol, in which case
//				// it goes on the left
//				if right.isData, !left.isData {
//					swap(&left, &right)
//				}
//
//				branches.append(.branch(left: left, right: right))
//			}
//
//			tree = branches.first ?? symbols.first!
//		}
//
//		// print(tree.mermaidDiagram())
//
//		// MARK: write tree
//
//		// rounded up to align to the nearest word
//		let nodeCount = (tree.nodeCount() + 1).roundedUpToTheNearest(4) - 1
//		let branchNodeCount = (nodeCount - 1) / 2
//		precondition(branchNodeCount <= Byte.max)
//		outputData.write(Byte(branchNodeCount))
//
//		var nodeWritingQueue: ArraySlice = [tree]
//
//		while let node = nodeWritingQueue.popFirst() {
//			switch node.kind {
//				case .symbol(let symbol):
//					outputData.write(symbol)
//				case .branch(left: let left, right: let right):
//					var nodeData = Byte(nodeWritingQueue.count / 2)
//
//					// children offset should fit in lower 5 bits
//					precondition(nodeData & 0b11111 == nodeData, "more nodes than should be possible")
//
//					if left.isData {
//						nodeData |= 1 << 7
//					}
//
//					if right.isData {
//						nodeData |= 1 << 6
//					}
//
//					outputData.write(nodeData)
//
//					nodeWritingQueue.append(left)
//					nodeWritingQueue.append(right)
//			}
//		}
//
//		outputData.fourByteAlign()
//
//		// MARK: write data
//
//		let dictionary = tree.dictionary()
////		print(dictionary)
//
//		var currentWord: BitArray? = nil
//
//		for byte in inputData { // e0046 stops too soon...?
//			if currentWord == nil {
//				currentWord = BitArray()
//			}
//
//			guard let newBits = dictionary[byte] else {
//				fatalError("this should never happen... right?")
//			}
//
////			print(String(byte, radix: 16, uppercase: true), newBits)
//
//			if let overflow = currentWord!.append(contentsOf: newBits) {
////				print(currentWord!)
//				currentWord!.write(to: outputData)
//				currentWord = overflow
//			}
//		}
//
//		currentWord?.write(to: outputData)
//
//		outputData.fourByteAlign()
//
//		return outputData.intoDatastream()
//	}
}
