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
	
	static func decompress(_ inputData: Datastream) throws -> Datastream {
		let base = inputData.offset
		
		let header = try inputData.read(CompressionHeader.self)
		assert(header.type == .huffman)
		
		let inputData = inputData.bytes[inputData.offset...]
		
		var outputData = [UInt8]()
		outputData.reserveCapacity(Int(header.decompressedSize))
		
		let treeNodeCount = Int(inputData.first!)
		let treeLength = (treeNodeCount + 1) * 2 - 1
		var bitstreamOffset = base + 5 + treeLength
		
		let rootNode = Node(from: inputData, at: 5, relativeTo: base)
		var currentNode = rootNode
		
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
			
			guard case .tree(let left, let right) = currentNode else {
				fatalError("this will never occur")
			}
			
			let currentBit = chunk >> chunkBit & 1
			if currentBit == 0 {
				currentNode = left
			} else {
				currentNode = right
			}
			
			if case .data(let byte) = currentNode {
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
				
				currentNode = rootNode
			}
			
			if chunkBit == 0 {
				chunkBit = 31
			} else {
				chunkBit -= 1
			}
		}
		
		return Datastream(outputData)
	}
	
	indirect enum Node {
		case tree(left: Node, right: Node)
		case data(byte: UInt8)
		
		init(
			from data: ArraySlice<UInt8>,
			at currentOffset: Int,
			relativeTo baseOffset: Int,
			isData: Bool = false
		) {
			let nodeData = data[baseOffset + currentOffset]
			
			if isData {
				self = .data(byte: nodeData)
			} else {
				let offset = Int(nodeData) & 0b111111
				let leftOffset = (currentOffset & ~1) + offset * 2 + 2
				let rightOffset = leftOffset + 1
				
				self = .tree(
					left:  Node(
						from: data,
						at: leftOffset,
						relativeTo: baseOffset,
						isData: nodeData >> 7 & 1 > 0
					),
					right: Node(
						from: data,
						at: rightOffset,
						relativeTo: baseOffset,
						isData: nodeData >> 6 & 1 > 0
					)
				)
			}
		}
	}
}
