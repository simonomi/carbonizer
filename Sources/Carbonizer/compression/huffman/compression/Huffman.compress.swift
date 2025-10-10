import BinaryParser

extension Huffman {
	struct CompressionNeedsExternalMetadata: Error, CustomStringConvertible {
		var description: String {
			"this ROM doesn't have external metadata, but compression requires it"
		}
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
	static func compress(_ inputData: Datastream, info: CompressionInfo?) throws -> Datastream {
		guard let info else {
			throw CompressionNeedsExternalMetadata()
		}
		
		let originalInputData = inputData.bytes[inputData.offset...]
		let outputData = Datawriter()
		
//		let uniqueByteCount = Set(originalInputData).count
		
		// note: map should be 8
		// either when 8 or when map, builds the tree wrong :/
		
		// TODO: how is data size determined....?
		// oh god is it based on how well its compressed??
		// add a flag in metadata for this?
		// theory: based on the number of unique bytes? whats the max?
		// - nope, both 4-bit and 8-bit have 0-256 unique bytes
		//  - or does it depend on the *shape* of the tree... grrrr
		
		// overall algorithm
		// - header stuff
		// - create tree
		// - write tree
		// - write data
		
		// TODO: is defaulting to 8 the right behavior? probably not
		// try to build an 8-bit tree, if that fails build a 4-bit one?
//		let dataSize = info?.dataSize ?? 4
//		precondition(dataSize == 4 || dataSize == 8, "huffman data size must be 4 or 8")
		
		let header = CompressionHeader(
			dataSize: info.dataSize,
			type: .huffman,
			decompressedSize: UInt32(originalInputData.count)
		)
		header.write(to: outputData)
		
		guard originalInputData.isNotEmpty else { return outputData.intoDatastream() }
		
		let inputData = if header.dataSize == 4 {
			originalInputData.flatMap { [$0 & 0b1111, $0 >> 4] }[...]
		} else {
			originalInputData
		}
		
		// TODO: make 4-bit and 8-bit and validate both?
		let tree: CompressionNode
//		if let givenTree = info.tree {
//			print(info.tree.mermaidDiagram())
			tree = CompressionNode(info.tree)
//			print(tree.mermaidDiagram())
//			print()
//		} else {
//			precondition(header.dataSize == 4)
//			tree = makeTree(
//				inputData: inputData,
//				dataSize: header.dataSize
//			)
//		}
		
		// print(tree.mermaidDiagram())
		
		// TODO: this can fail if the tree is the wrong shape, add validation step
		tree.write(to: outputData)
		
		// TODO: right now this is failing because it cant find a value for 0x7F in image_archive>0050
		// - because of differing lzss/runlength compression? which file in particular?
		// TODO: related problem: what happens if the user modifies a file to have
		// a byte never used in the original? we need to make a new tree
		try tree.write(inputData, to: outputData)
		
		return outputData.intoDatastream()
	}
}
