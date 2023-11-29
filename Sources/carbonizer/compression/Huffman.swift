//
//  Huffman.swift
//
//
//  Created by alice on 2023-11-28.
//

import BinaryParser

enum Huffman {
	static func compress(_ data: Datastream) -> Datastream {
		fatalError("TODO:")
	}
	
//	static func decompress(_ inputData: Datastream) throws -> Datastream {
//		let base = inputData.placeMarker()
//		
//		let header = try inputData.read(CompressionHeader.self)
//		assert(header.type == .huffman)
//		
//		let outputData = Datawriter(capacity: Int(header.decompressedSize))
//		
//		let treeNodeCount = Int(try inputData.read(UInt8.self))
//		
//		let treeStart = inputData.placeMarker()
//		let treeLength = (treeNodeCount + 1) * 2 - 1
//		
//		let rootNode = try Node(from: inputData, at: 5, relativeTo: base)
//		
//		var currentNode = rootNode
//		var halfWritten: UInt8?
//		inputData.jump(to: treeStart + treeLength)
//		
//		while outputData.offset < header.decompressedSize {
//			let nodeBits = try inputData.read(UInt32.self)
//			
//			for bitOffset in (1...32) {
//				let bit = nodeBits >> (32 - bitOffset) & 1
//				guard case .tree(let left, let right) = currentNode else {
//					fatalError("this will never occur")
//				}
//				
//				if bit == 0 {
//					currentNode = left
//				} else {
//					currentNode = right
//				}
//				
//				if case .data(let byte) = currentNode {
//					if header.dataSize == 4 {
//						if let nybble = halfWritten {
//							outputData.write(byte << 4 | nybble)
//							halfWritten = nil
//						} else {
//							halfWritten = byte
//						}
//					} else {
//						outputData.write(byte)
//					}
//					currentNode = rootNode
//					
//					if outputData.offset >= header.decompressedSize {
//						break
//					}
//				}
//			}
//		}
//		
//		return outputData.intoDatastream()
//	}
	
	static func decompress(_ inputData: Datastream) throws -> Datastream {
		let base = inputData.offset
		
		let header = try inputData.read(CompressionHeader.self)
		assert(header.type == .huffman)
		
		var inputData = inputData.bytes[inputData.offset...]
		
		var outputData = [UInt8]()
		outputData.reserveCapacity(Int(header.decompressedSize))
		
		let treeNodeCount = Int(inputData.removeFirst())
		let treeLength = (treeNodeCount + 1) * 2 - 1
		var bitstreamOffset = base + 5 + treeLength
		
		let rootNodeOffset = 5
		var currentNodeOffset = rootNodeOffset
		
		var chunkBit = 31
		var chunk: UInt32!
		
		var halfWritten: UInt8?
		
		while outputData.count < header.decompressedSize {
			if chunkBit == 31 {
				chunk = UInt32(inputData[bitstreamOffset]) |
						UInt32(inputData[bitstreamOffset + 1]) << 8 |
						UInt32(inputData[bitstreamOffset + 2]) << 16 |
						UInt32(inputData[bitstreamOffset + 3]) << 24
				bitstreamOffset += 4
			}
			
			let currentBit = chunk >> chunkBit & 1
			let currentNode = inputData[base + currentNodeOffset]
			let isData: Bool
			if currentBit == 0 {
				(currentNodeOffset, isData) = leftChild(of: currentNode, at: currentNodeOffset)
			} else {
				(currentNodeOffset, isData) = rightChild(of: currentNode, at: currentNodeOffset)
			}
			
			if isData {
				let byte = inputData[base + currentNodeOffset]
				
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
			
			if chunkBit == 0 {
				chunkBit = 31
			} else {
				chunkBit -= 1
			}
		}
		
		return Datastream(outputData)
	}
	
	typealias ChildNode = (offset: Int, isData: Bool)
	
	static func leftChild(of currentNode: UInt8, at currentOffset: Int) -> ChildNode {
		let offset = Int(currentNode) & 0b111111
		return (
			offset: currentOffset & ~1 + offset * 2 + 2,
			isData: currentNode >> 7 & 1 > 0
		)
	}
	
	static func rightChild(of currentNode: UInt8, at currentOffset: Int) -> ChildNode {
		let offset = Int(currentNode) & 0b111111
		return (
			offset: currentOffset & ~1 + offset * 2 + 2 + 1,
			isData: currentNode >> 6 & 1 > 0
		)
	}
	
//	indirect enum Node {
//		case tree(left: Node, right: Node)
//		case data(UInt8)
//		
//		init(from data: Datastream, at offset: Int, relativeTo baseOffset: Datastream.Offset, isData: Bool = false) throws {
//			data.jump(to: baseOffset + offset)
//			let nodeData = try data.read(UInt8.self)
//			
//			if isData {
//				self = .data(nodeData)
//			} else {
//				let currentOffset = offset
//				let offset = Int(nodeData) & 0b111111
//				let leftOffset = (currentOffset & ~1) + offset * 2 + 2
//				let rightOffset = leftOffset + 1
//				
//				self = .tree(
//					left:  try Node(
//						from: data,
//						at: leftOffset,
//						relativeTo: baseOffset,
//						isData: nodeData & 0b10000000 > 0
//					),
//					right: try Node(
//						from: data,
//						at: rightOffset,
//						relativeTo: baseOffset,
//						isData: nodeData & 0b01000000 > 0
//					)
//				)
//			}
//		}
//	}
}
