func dtxRipper(_ fileSystemObject: any FileSystemObject) -> [String] {
	let nds = fileSystemObject as! NDS
	let text = nds.contents.first { $0.name == "text" } as! Folder
	let japanese = text.contents.first { $0.name == "japanese" }! as! MAR
	let dtx = japanese.files.first!.content as! DTX
	return dtx.strings
}
