import BinaryParser

fileprivate func dropLowestBit<T: FixedWidthInteger>(of number: T) -> T {
	number & ~1
}

// https://mgba-emu.github.io/gbatek/#huffuncompreadbycallback---swi-13h-ndsdsi
enum Huffman {
	static func compress(_ data: Datastream) -> Datastream {
		fatalError("TODO:")
	}
	
	static func decompress(_ inputData: Datastream) throws -> Datastream {
		let base = inputData.offset
		
		let header = try inputData.read(CompressionHeader.self)
		precondition(header.type == .huffman)
		precondition(header.decompressedSize > 0)
		
		let inputData = inputData.bytes[inputData.offset...]
		
		var outputData = [UInt8]()
		outputData.reserveCapacity(Int(header.decompressedSize))
		
		let treeNodeCount = Int(inputData.first!)
		let treeLength = 2 * treeNodeCount + 1
		
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
		
		return Datastream(outputData)
	}
	
	struct Node {
		var nodeData: UInt8
		
		func leftOffset(currentOffset: Int) -> Int {
			let offset = Int(nodeData) & 0b111111 + 1
			return dropLowestBit(of: currentOffset) + 2 * offset
		}
		
		var leftIsData: Bool {
			nodeData >> 7 & 1 > 0
		}
		
		func rightOffset(currentOffset: Int) -> Int {
			let offset = Int(nodeData) & 0b111111 + 1
			return dropLowestBit(of: currentOffset) + 2 * offset + 1
		}
		
		var rightIsData: Bool {
			nodeData >> 6 & 1 > 0
		}
	}
	
	// this is the old version of decompress. it was about twice as slow,
	// but its a bit easier to read, so im keeping it around
//	static func oldDecompress(_ inputData: Datastream) throws -> Datastream {
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
//	indirect enum Node {
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
//	}
}
