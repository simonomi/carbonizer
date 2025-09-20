func museumLabeller(
	_ fileSystemObject: consuming any FileSystemObject,
	text: [String],
	configuration: Configuration
) -> any FileSystemObject {
	var nds = fileSystemObject as! NDS.Unpacked
	let etcFolderIndex = nds.contents.firstIndex { $0.name == "etc" }!
	var etcFolder = nds.contents[etcFolderIndex] as! Folder
	
	let museumDefsIndex = etcFolder.contents.firstIndex { $0.name == "museum_defs" }!
	var museumDefsMAR = etcFolder.contents[museumDefsIndex] as! MAR.Unpacked
	var museumDefs = museumDefsMAR.files.first!.content as! DML.Unpacked
	
	for (index, vivosaur) in museumDefs.vivosaurs.enumerated() {
		museumDefs.vivosaurs[index]._description = text[Int(vivosaur.descriptionIndex)]
	}
	
	museumDefsMAR.files[0].content = museumDefs
	etcFolder.contents[museumDefsIndex] = museumDefsMAR
	nds.contents[etcFolderIndex] = etcFolder
	return nds
}
