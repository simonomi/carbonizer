func keyItemLabeller(
	_ fileSystemObject: consuming any FileSystemObject,
	text: [String],
	configuration: CarbonizerConfiguration
) -> any FileSystemObject {
	var nds = fileSystemObject as! NDS.Unpacked
	let etcFolderIndex = nds.contents.firstIndex { $0.name == "etc" }!
	var etcFolder = nds.contents[etcFolderIndex] as! Folder
	
	let keyitemDefsIndex = etcFolder.contents.firstIndex { $0.name == "keyitem_defs" }!
	var keyitemDefsMAR = etcFolder.contents[keyitemDefsIndex] as! MAR.Unpacked
	var keyitemDefs = keyitemDefsMAR.files.first!.content as! KIL.Unpacked
	
	for (index, keyItem) in keyitemDefs.keyItems.enumerated() where keyItem != nil {
		keyitemDefs.keyItems[index]!._name = text[Int(keyItem!.nameIndex)]
		keyitemDefs.keyItems[index]!._description = text[Int(keyItem!.descriptionIndex)]
	}
	
	keyitemDefsMAR.files[0].content = keyitemDefs
	etcFolder.contents[keyitemDefsIndex] = keyitemDefsMAR
	nds.contents[etcFolderIndex] = etcFolder
	return nds
}
