func hmlNameLabeller(
	_ fileSystemObject: consuming any FileSystemObject,
	text: [String],
	configuration: CarbonizerConfiguration
) -> any FileSystemObject {
	var nds = fileSystemObject as! NDS.Unpacked
	let etcFolderIndex = nds.contents.firstIndex { $0.name == "etc" }!
	var etcFolder = nds.contents[etcFolderIndex] as! Folder
	
	let headmaskDefsIndex = etcFolder.contents.firstIndex { $0.name == "headmask_defs" }!
	var headmaskDefsMAR = etcFolder.contents[headmaskDefsIndex] as! MAR.Unpacked
	var headmaskDefs = headmaskDefsMAR.files.first!.content as! HML.Unpacked
	
	for (index, mask) in headmaskDefs.masks.enumerated() {
		headmaskDefs.masks[index]._name = text[Int(mask.name)]
		headmaskDefs.masks[index]._japaneseDebugName = text[Int(mask.japaneseDebugName)]
	}
	
	headmaskDefsMAR.files[0].content = headmaskDefs
	etcFolder.contents[headmaskDefsIndex] = headmaskDefsMAR
	nds.contents[etcFolderIndex] = etcFolder
	return nds
}
