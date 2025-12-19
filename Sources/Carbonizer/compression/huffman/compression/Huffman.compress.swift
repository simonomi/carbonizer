import BinaryParser

extension Huffman {
	struct CompressionNeedsExternalMetadata: Error, CustomStringConvertible {
		var description: String {
			"this ROM doesn't have external metadata, but compression requires it"
		}
	}
	
	static func compress(_ originalInputData: ByteSlice, info: CompressionInfo?) throws -> ByteSlice {
		guard let info else {
			throw CompressionNeedsExternalMetadata()
		}
		
		let outputData = Datawriter()
		
		let header = CompressionHeader(
			dataSize: info.dataSize,
			type: .huffman,
			decompressedSize: UInt32(originalInputData.count)
		)
		header.write(to: outputData)
		
		guard originalInputData.isNotEmpty else { return outputData.bytes }
		
		let inputData = if header.dataSize == 4 {
			originalInputData.flatMap { [$0 & 0b1111, $0 >> 4] }[...]
		} else {
			originalInputData
		}
		
		let originalTree = CompressionNode(info.tree)
		
		let tree: CompressionNode
		if originalTree.symbols() == Set(inputData) {
			try originalTree.write(to: outputData)
			tree = originalTree
		} else {
			do {
				// first, try to make a new tree with the same data size, to minimize changes
				let sameSizeTree = makeTree(inputData: inputData, dataSize: header.dataSize)
				try sameSizeTree.write(to: outputData)
				tree = sameSizeTree
			} catch {
				// if that fails, try the other data size, and if *that* fails, just fail entirely
				// (but that should be impossible because 16-symbol trees always succeed?)
				let otherDataSize: UInt8 = if header.dataSize == 4 { 8 } else { 4 }
				
				let otherSizeTree = makeTree(inputData: inputData, dataSize: otherDataSize)
				try otherSizeTree.write(to: outputData)
				tree = otherSizeTree
			}
		}
		
		try tree.write(inputData, to: outputData)
		
		return outputData.bytes
	}
}
