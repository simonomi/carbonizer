func mapLabeller(
	_ fileSystemObject: consuming any FileSystemObject,
	text: [String],
	configuration: Carbonizer.Configuration
) -> any FileSystemObject {
	var nds = fileSystemObject as! NDS.Unpacked
	let mapFolderIndex = nds.contents.firstIndex { $0.name == "map" }!
	var mapFolder = nds.contents[mapFolderIndex] as! Folder
	
	let mFolderIndex = mapFolder.contents.firstIndex { $0.name == "m" }!
	var mFolder = mapFolder.contents[mFolderIndex] as! Folder
	
	mFolder.contents = mFolder.contents
		.map {
			var mar = $0 as! MAR.Unpacked
			var map = mar.files.first!.content as! MAP.Unpacked
			
			map._bannerText = text[safely: Int(map.bannerTextID)]
			
			mar.files[0].content = map
			
			return mar
		}
	
	mapFolder.contents[mFolderIndex] = mFolder
	nds.contents[mapFolderIndex] = mapFolder
	return nds
}
