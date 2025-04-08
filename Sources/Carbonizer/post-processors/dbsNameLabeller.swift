func dbsNameLabeller(
	_ fileSystemObject: consuming any FileSystemObject,
	text: [String],
	configuration: CarbonizerConfiguration
) -> any FileSystemObject {
	var nds = fileSystemObject as! NDS
	let battleFolderIndex = nds.contents.firstIndex { $0.name == "battle" }!
	var battleFolder = nds.contents[battleFolderIndex] as! Folder
	
	let episodeFiles = battleFolder.contents
		.map { $0 as! MAR }
		.map {
			var mar = $0
			var content = $0.files.first!.content as! DBS
			
			if var fighter1 = content.fighter1 {
				fighter1.name._label = text[safely: Int(fighter1.name.id)]
				content.fighter1 = fighter1
			}
			
			content.fighter2.name._label = text[safely: Int(content.fighter2.name.id)]
			
			mar.files[0].content = content
			
			return mar
		}
	
	battleFolder.contents = episodeFiles
	nds.contents[battleFolderIndex] = battleFolder
	return nds
}
