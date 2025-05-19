import BinaryParser

// https://mgba-emu.github.io/gbatek/#huffuncompreadbycallback---swi-13h-ndsdsi
enum Huffman {
	struct CompressionInfo: Codable {
		var dataSize: UInt8
		var tree: Node?
		
		indirect enum Node: Codable {
			case symbol(Byte)
			case branch(left: Self, right: Self)
			
			enum BranchCodingKeys: CodingKey {
				case left, right
			}
			
			init(from decoder: any Decoder) throws {
				do {
					let symbol = try decoder.singleValueContainer().decode(Byte.self)
					
					self = .symbol(symbol)
				} catch {
					let container = try decoder.container(keyedBy: BranchCodingKeys.self)
					
					let left = try container.decode(Self.self, forKey: .left)
					let right = try container.decode(Self.self, forKey: .right)
					
					self = .branch(left: left, right: right)
				}
			}
			
			func encode(to encoder: any Encoder) throws {
				switch self {
					case .symbol(let byte):
						var container = encoder.singleValueContainer()
						try container.encode(byte)
					case .branch(let left, let right):
						var container = encoder.container(keyedBy: BranchCodingKeys.self)
						
						try container.encode(left, forKey: .left)
						try container.encode(right, forKey: .right)
				}
			}
			
			init(
				traversing data: ArraySlice<Byte>,
				at currentOffset: Int,
				isData: Bool = false
			) {
				let nodeData = data[currentOffset]
				
				if isData {
					self = .symbol(nodeData)
				} else {
					let huffmanNode = Huffman.Node(nodeData: nodeData)
					
					self = .branch(
						left: Self(
							traversing: data,
							at: huffmanNode.leftOffset(currentOffset: currentOffset),
							isData: huffmanNode.leftIsData
						),
						right: Self(
							traversing: data,
							at: huffmanNode.rightOffset(currentOffset: currentOffset),
							isData: huffmanNode.rightIsData
						)
					)
				}
			}
		}
	}
	
//	static func compress(_ inputData: Datastream, info: CompressionInfo?) -> Datastream {
//		todo()
//	}
	
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
////		print(tree)
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
	}
	
	struct BitArray: CustomDebugStringConvertible {
		var data: UInt32
		var count: Int
		
		init() {
			data = 0
			count = 0
		}
		
		private init(data: UInt32, count: Int) {
			self.data = data
			self.count = count
		}
		
		static let maxCount = 32
		
		mutating func append(_ bit: Bool) {
			precondition(count < Self.maxCount)
			count += 1
			if bit {
				data |= 1 << (Self.maxCount - count)
			}
		}
		
		consuming func appending(_ bit: Bool) -> Self {
			append(bit)
			return self
		}
		
		mutating func prepend(_ bit: Bool) {
			precondition(count < Self.maxCount)
			count += 1
			data >>= 1
			if bit {
				data |= 1 << (Self.maxCount - 1)
			}
		}
		
		consuming func prepending(_ bit: Bool) -> Self {
			prepend(bit)
			return self
		}
		
		mutating func append(contentsOf other: Self) -> Self? {
			let overflow: Self?
			(self, overflow) = self + other
			return overflow
		}
		
		func write(to data: Datawriter) {
			data.write(self.data)
		}
		
		static func + (_ left: Self, _ right: Self) -> (Self, overflow: Self?) {
			if left.count + right.count <= maxCount {
				(
					Self(
						data: left.data | (right.data >> left.count),
						count: left.count + right.count
					),
					nil
				)
			} else {
				(
					Self(
						data: left.data | (right.data >> left.count),
						count: maxCount
					),
					Self(
						data: right.data << (maxCount - left.count),
						count: (right.count + left.count) - maxCount
					)
				)
			}
		}
		
		var debugDescription: String {
			if count == 0 {
				"[]"
			} else {
				"[" + (1...count)
					.map { Self.maxCount - $0 }
					.map { (data >> $0) & 1 }
					.map {
						if $0 == 0 {
							"0"
						} else {
							"1"
						}
					}
					.joined() + "]"
			}
		}
	}
	
	static func decompress(_ inputData: Datastream) throws -> (Datastream, CompressionInfo) {
		let base = inputData.offset
		
		let header = try inputData.read(CompressionHeader.self)
		precondition(header.type == .huffman)
		precondition(header.decompressedSize > 0)
		precondition(header.dataSize == 4 || header.dataSize == 8)
		
		let inputData = inputData.bytes[inputData.offset...]
		
		var outputData = [UInt8]()
		outputData.reserveCapacity(Int(header.decompressedSize))
		
		let branchNodeCount = Int(inputData.first!)
		let treeLength = 2 * branchNodeCount + 1
		
		let rootNodeOffset = base + 5
		var currentNodeOffset = rootNodeOffset
		
		var halfWritten: UInt8?
		
		var bitstreamOffset = rootNodeOffset + treeLength
		
	mainloop:
		while true {
			let chunk = UInt32(inputData[bitstreamOffset]) |
						UInt32(inputData[bitstreamOffset + 1]) << 8 |
						UInt32(inputData[bitstreamOffset + 2]) << 16 |
						UInt32(inputData[bitstreamOffset + 3]) << 24
			bitstreamOffset += 4
			
			for chunkBit in (0..<32).reversed() {
				let node = Node(nodeData: inputData[currentNodeOffset])
				
				let isData: Bool
				
				let currentBit = chunk >> chunkBit & 1
				if currentBit == 0 {
					currentNodeOffset = node.leftOffset(currentOffset: currentNodeOffset)
					isData = node.leftIsData
				} else {
					currentNodeOffset = node.rightOffset(currentOffset: currentNodeOffset)
					isData = node.rightIsData
				}
				
				if isData {
					let byte = inputData[currentNodeOffset]
					
					if header.dataSize == 4 {
						if let nybble = halfWritten {
							outputData.append(byte << 4 | nybble)
							halfWritten = nil
						} else {
							halfWritten = byte
						}
					} else {
						outputData.append(byte)
					}
					
					currentNodeOffset = rootNodeOffset
				}
				
				guard outputData.count < header.decompressedSize else {
					break mainloop
				}
			}
		}
		
		let tree: CompressionInfo.Node? = if header.dataSize == 8 {
			CompressionInfo.Node(traversing: inputData, at: rootNodeOffset)
		} else {
			nil
		}
		
		let compressionInfo = CompressionInfo(dataSize: header.dataSize, tree: tree)
		
		return (Datastream(outputData), compressionInfo)
	}
	
	struct Node {
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
		
		fileprivate func dropLowestBit<T: FixedWidthInteger>(of number: T) -> T {
			number & ~1
		}
	}
	
	// this is the old version of decompress. it was about twice as slow,
	// but its a bit easier to read, so im keeping it around
//	static func decompress(_ inputData: Datastream) throws -> Datastream {
//		let base = inputData.offset
//		
//		let header = try inputData.read(CompressionHeader.self)
//		precondition(header.type == .huffman)
//		precondition(header.decompressedSize > 0)
//		
//		let inputData = inputData.bytes[inputData.offset...]
//		
//		var outputData = [UInt8]()
//		outputData.reserveCapacity(Int(header.decompressedSize))
//		
//		let treeNodeCount = Int(inputData.first!)
//		let treeLength = (treeNodeCount + 1) * 2 - 1
//		var bitstreamOffset = base + 5 + treeLength
//		
//		let rootNode = Node(from: inputData, at: 5, relativeTo: base)
//		var currentNode = rootNode
//		
//		print(rootNode)
//
//		var halfWritten: UInt8?
//		
//	mainloop:
//		while true {
//			let chunk = UInt32(inputData[bitstreamOffset]) |
//						UInt32(inputData[bitstreamOffset + 1]) << 8 |
//						UInt32(inputData[bitstreamOffset + 2]) << 16 |
//						UInt32(inputData[bitstreamOffset + 3]) << 24
//			bitstreamOffset += 4
//			
//			for chunkBit in (0..<32).reversed() {
//				guard case .tree(let left, let right) = currentNode else {
//					fatalError("this will never occur")
//				}
//				
//				let currentBit = chunk >> chunkBit & 1
//				if currentBit == 0 {
//					currentNode = left
//				} else {
//					currentNode = right
//				}
//				
//				if case .data(let byte) = currentNode {
//					if header.dataSize == 4 {
//						if let nybble = halfWritten {
//							outputData.append(byte << 4 | nybble)
//							halfWritten = nil
//						} else {
//							halfWritten = byte
//						}
//					} else {
//						outputData.append(byte)
//					}
//					
//					currentNode = rootNode
//				}
//				
//				guard outputData.count < header.decompressedSize else {
//					break mainloop
//				}
//			}
//		}
//		
//		return Datastream(outputData)
//	}
//	
//	indirect enum Node: CustomDebugStringConvertible {
//		case tree(left: Node, right: Node)
//		case data(byte: UInt8)
//		
//		init(
//			from data: ArraySlice<UInt8>,
//			at currentOffset: Int,
//			relativeTo baseOffset: Int,
//			isData: Bool = false
//		) {
//			let nodeData = data[baseOffset + currentOffset]
//			
//			if isData {
//				self = .data(byte: nodeData)
//			} else {
//				let offset = Int(nodeData) & 0b111111
//				let leftOffset = (currentOffset & ~1) + offset * 2 + 2
//				let rightOffset = leftOffset + 1
//				
//				self = .tree(
//					left:  Node(
//						from: data,
//						at: leftOffset,
//						relativeTo: baseOffset,
//						isData: nodeData >> 7 & 1 > 0
//					),
//					right: Node(
//						from: data,
//						at: rightOffset,
//						relativeTo: baseOffset,
//						isData: nodeData >> 6 & 1 > 0
//					)
//				)
//			}
//		}
//		
//		var debugDescription: String {
//			switch self {
//				case .data(let byte):
//					String(byte, radix: 16, uppercase: true)
//				case .tree(let left, let right):
//					"node \(left) \(right)"
//			}
//		}
//	}
}
