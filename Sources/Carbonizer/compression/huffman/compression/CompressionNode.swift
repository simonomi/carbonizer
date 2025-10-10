import BinaryParser

extension Huffman {
	struct CompressionNode: Comparable, CustomDebugStringConvertible {
		var kind: Kind
		var frequency: Int
		
		indirect enum Kind: Equatable {
			case symbol(Byte)
			case branch(left: CompressionNode, right: CompressionNode)
		}
		
		var isData: Bool {
			switch kind {
				case .symbol: true
				case .branch: false
			}
		}
		
		static func symbol(_ symbol: Byte, frequency: Int) -> Self {
			Self(kind: .symbol(symbol), frequency: frequency)
		}
		
		static func branch(left: Self, right: Self) -> Self {
			Self(
				kind: .branch(left: left, right: right),
				frequency: left.frequency + right.frequency
			)
		}
		
		static func < (_ left: Self, _ right: Self) -> Bool {
			if left.frequency == right.frequency,
			   case let .symbol(leftSymbol) = left.kind,
			   case let .symbol(rightSymbol) = right.kind
			{
				leftSymbol < rightSymbol
			} else {
				left.frequency < right.frequency
			}
		}
		
		func nodeCount() -> Int {
			switch kind {
				case .symbol:
					1
				case .branch(let left, let right):
					1 + left.nodeCount() + right.nodeCount()
			}
		}
		
		func dictionary() -> [Byte: BitArray] {
			switch kind {
				case .symbol(let byte):
					[byte: BitArray()]
				case .branch(let left, let right):
					left.dictionary()
						.mapValues { $0.prepending(false) }
						.merging(
							right.dictionary().mapValues { $0.prepending(true) },
							uniquingKeysWith: { _,_ in fatalError("unreachable") }
						)
			}
		}
		
		var debugDescription: String {
			switch kind {
				case .symbol(let byte):
					"\(frequency)x\(String(byte, radix: 16, uppercase: true))"
				case .branch(let left, let right):
					"\(frequency)xnode \(left) \(right)"
			}
		}
		
		func mermaidDiagram() -> String {
			var nodeIndex = 0
			return (
				["```mermaid", "graph TD"] +
				mermaidConnections(&nodeIndex).connections.map { "\t" + $0 } +
				["```"]
			)
			.joined(separator: "\n")
		}
		
		private func mermaidConnections(_ index: inout Int) -> (name: String, connections: [String]) {
			switch kind {
				case .symbol(let byte):
					let myName = "\(frequency)x0x" + String(byte, radix: 16, uppercase: true)
					return (
						myName,
						["style \(myName) fill:#00c7de"]
					)
				case .branch(let left, let right):
					let myName = "\(frequency)x\(index)"
					
					index += 1
					let left = left.mermaidConnections(&index)
					let right = right.mermaidConnections(&index)
					
					return (
						myName,
						[
							"\(myName) --> \(left.name)",
							"\(myName) --> \(right.name)"
						] + left.connections + right.connections
					)
			}
		}
		
		// TODO: remove
		func hasChild(_ other: Self) -> Bool {
			switch kind {
				case .symbol: false
				case .branch(let left, let right):
					left == other || right == other || left.hasChild(other) || right.hasChild(other)
			}
		}
		
		init(kind: Kind, frequency: Int) {
			self.kind = kind
			self.frequency = frequency
		}
		
		init(_ infoNode: Huffman.CompressionInfo.Node) {
			frequency = 0 // frequency should only be used when *creating* the tree
			
			switch infoNode {
				case .symbol(let byte):
					kind = .symbol(byte)
				case .branch(let left, let right):
					kind = .branch(
						left: Self(left),
						right: Self(right)
					)
			}
		}
		
		func write(to output: Datawriter) {
			// rounded up to align to the nearest word
			let nodeCount = (self.nodeCount() + 1).roundedUpToTheNearest(4) - 1
			let branchNodeCount = (nodeCount - 1) / 2
			precondition(branchNodeCount <= Byte.max)
			output.write(Byte(branchNodeCount))
			
			// TODO: this algorithm is wrong, it fails for kaseki_defs
			var nodeWritingQueue: ArraySlice = [self]
			
			while let node = nodeWritingQueue.popFirst() {
				switch node.kind {
					case .symbol(let symbol):
						output.write(symbol)
					case .branch(left: let left, right: let right):
						var nodeData = Byte(nodeWritingQueue.count / 2)
						
						// children offset should fit in lower 6 bits
						precondition(nodeData & 0b111111 == nodeData, "more nodes than should be possible")
						
						if left.isData {
							nodeData |= 1 << 7
						}
						
						if right.isData {
							nodeData |= 1 << 6
						}
						
						output.write(nodeData)
						
						nodeWritingQueue.append(left)
						nodeWritingQueue.append(right)
				}
			}
			
			output.fourByteAlign()
		}
		
		struct TreeMissingValue: Error, CustomStringConvertible {
			var key: UInt8
			
			var description: String {
				"the huffman tree is missing a value for \(.cyan)\(key)\(.normal)"
			}
		}
		
		func write(_ inputData: ArraySlice<UInt8>, to output: Datawriter) throws {
			let dictionary = dictionary()
//			print(dictionary)
			
			var currentWord: BitArray? = nil
			
			for byte in inputData { // e0046 stops too soon...?
				if currentWord == nil {
					currentWord = BitArray()
				}
				
				guard let newBits = dictionary[byte] else {
					print()
					throw TreeMissingValue(key: byte)
				}
				
//				print(String(byte, radix: 16, uppercase: true), newBits)
				
				if let overflow = currentWord!.append(contentsOf: newBits) {
//					print(currentWord!)
					currentWord!.write(to: output)
					currentWord = overflow
				}
			}
			
			currentWord?.write(to: output)
			
			output.fourByteAlign()
		}
	}
}
