//
//  Huffman.swift
//  
//
//  Created by simon pellerin on 2023-06-19.
//

import Foundation

enum Huffman {
	static func compress(_ data: Data) throws -> Data {
		fatalError("cannot compress huffman")
	}
	
	static func decompress(_ data: Data) throws -> Data {
		let inputData = Datastream(data)
		let outputData = Datawriter()
		
		let header = try CompressionHeader(from: inputData)
		
		let treeNodeCount = try inputData.read(UInt8.self)
		let treeLength = (Int(treeNodeCount) + 1) * 2 - 1
		
		let rootNode = try Node(from: inputData, at: inputData.offset)
		
		var currentNode = rootNode
		var halfWritten: UInt8?
		inputData.seek(to: 5 + treeLength)
		
		while outputData.offset < header.decompressedSize {
			let nodeBits = try inputData.read(UInt32.self)
			
			(0..<32).reversed().forEach {
				let bit = nodeBits >> $0 & 1
				guard case .tree(let left, let right) = currentNode else {
					fatalError("this will never occur")
				}
				
				if bit == 0 {
					currentNode = left
				} else {
					currentNode = right
				}
				
				if case .data(let byte) = currentNode {
					if header.dataSize == 4 {
						if let nybble = halfWritten {
							outputData.write(byte << 4 | nybble)
							halfWritten = nil
						} else {
							halfWritten = byte
						}
					} else {
						outputData.write(byte)
					}
					currentNode = rootNode
				}
			}
		}
		
		return outputData.data
	}
	
	indirect enum Node {
		case tree(left: Node, right: Node)
		case data(UInt8)
		
		init(from data: Datastream, at offset: Int, isData: Bool = false) throws {
			data.seek(to: offset)
			let nodeData = try data.read(UInt8.self)
			
			if isData {
				self = .data(nodeData)
			} else {
				let currentOffset = offset
				let offset = Int(nodeData) & 0b111111
				let leftOffset = (currentOffset & ~1) + offset * 2 + 2
				let rightOffset = leftOffset + 1
				
				self = .tree(
					left:  try Node(from: data, at: leftOffset,  isData: nodeData & 0b10000000 > 0),
					right: try Node(from: data, at: rightOffset, isData: nodeData & 0b01000000 > 0)
				)
			}
		}
	}
}
