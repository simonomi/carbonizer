func dexBlockLabellerF(
	_ mar: inout MAR.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	guard mar.files.count == 1,
		  var dex = mar.files.first?.content as? DEX.Unpacked
	else {
		return
	}
	
	let blockIDs = try environment.get(\.blockIDs)
	
	guard let relevantBlockIDs = blockIDs[String(mar.name.dropFirst())] else {
		return
	}
	
	for (blockIndex, blockID) in zip(dex.commands.indices, relevantBlockIDs) {
		let comment: DEX.Unpacked.Command = .comment("block \(blockID)")
		dex.commands[blockIndex].insert(comment, at: 0)
	}
	
	mar.files[0].content = dex
}
