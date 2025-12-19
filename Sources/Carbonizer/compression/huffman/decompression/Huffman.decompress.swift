import BinaryParser

// https://mgba-emu.github.io/gbatek/#huffuncompreadbycallback---swi-13h-ndsdsi
extension Huffman {
	static func decompress(_ inputData: consuming Datastream) throws -> (Datastream, CompressionInfo) {
		let base = inputData.offset
		
		let header = try inputData.read(CompressionHeader.self)
		precondition(header.type == .huffman) // TODO: better error
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
				let node = DecompressionNode(nodeData: inputData[currentNodeOffset])
				
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
		
		let tree = CompressionInfo.Node(traversing: inputData, at: rootNodeOffset)
		
//		if let tree {
//			print(tree.mermaidDiagram())
//		} else {
//			print(CompressionInfo.Node(traversing: inputData, at: rootNodeOffset).mermaidDiagram())
//		}
		
		let compressionInfo = CompressionInfo(dataSize: header.dataSize, tree: tree)
		
		return (Datastream(outputData), compressionInfo)
	}
}
