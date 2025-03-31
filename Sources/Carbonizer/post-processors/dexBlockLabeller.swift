func dexBlockLabeller(
	_ fileSystemObject: consuming any FileSystemObject,
	configuration: CarbonizerConfiguration
) -> any FileSystemObject {
	var nds = fileSystemObject as! NDS
	let episodeFolderIndex = nds.contents.firstIndex { $0.name == "episode" }!
	var episodeFolder = nds.contents[episodeFolderIndex] as! Folder
	
	let blockIDs: [String: [Int32]] = Dictionary(
		uniqueKeysWithValues: episodeFolder.contents
			.map { $0 as! MAR }
			.filter { $0.files.first!.content is DEP }
			.map { ($0.name, ($0.files.first!.content as! DEP).blocks.map(\.id)) }
	)
	
	var episodeFiles = episodeFolder.contents.map { $0 as! MAR }
	
	for index in episodeFiles.indices where episodeFiles[index].files.first!.content is DEX {
		let fileName = episodeFiles[index].name
		
		let relevantBlockIDs = blockIDs[String(fileName.dropFirst())]!
		
		var dex = episodeFiles[index].files.first!.content as! DEX
		
		for (blockIndex, blockID) in zip(dex.commands.indices, relevantBlockIDs) {
			let comment: DEX.Command = .comment("block \(blockID)")
			dex.commands[blockIndex].insert(comment, at: 0)
		}
		
		episodeFiles[index].files[0].content = dex
	}
	
	episodeFolder.contents = episodeFiles
	
	nds.contents[episodeFolderIndex] = episodeFolder
	
	return nds
}
