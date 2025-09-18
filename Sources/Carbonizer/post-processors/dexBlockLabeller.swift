func dexBlockLabeller(
	_ fileSystemObject: consuming any FileSystemObject,
	configuration: Carbonizer.Configuration
) -> any FileSystemObject {
	var nds = fileSystemObject as! NDS.Unpacked
	let episodeFolderIndex = nds.contents.firstIndex { $0.name == "episode" }!
	var episodeFolder = nds.contents[episodeFolderIndex] as! Folder
	
	let blockIDs: [String: [Int32]] = Dictionary(
		uniqueKeysWithValues: episodeFolder.contents
			.map { $0 as! MAR.Unpacked }
			.filter { $0.files.first!.content is DEP.Unpacked }
			.map { ($0.name, ($0.files.first!.content as! DEP.Unpacked).blocks.map(\.id)) }
	)
	
	var episodeFiles = episodeFolder.contents.map { $0 as! MAR.Unpacked }
	
	for index in episodeFiles.indices where episodeFiles[index].files.first!.content is DEX.Unpacked {
		let fileName = episodeFiles[index].name
		
		let relevantBlockIDs = blockIDs[String(fileName.dropFirst())]!
		
		var dex = episodeFiles[index].files.first!.content as! DEX.Unpacked
		
		for (blockIndex, blockID) in zip(dex.commands.indices, relevantBlockIDs) {
			let comment: DEX.Unpacked.Command = .comment("block \(blockID)")
			dex.commands[blockIndex].insert(comment, at: 0)
		}
		
		episodeFiles[index].files[0].content = dex
	}
	
	episodeFolder.contents = episodeFiles
	
	nds.contents[episodeFolderIndex] = episodeFolder
	
	return nds
}
