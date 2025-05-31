func dtxRipper(_ fileSystemObject: any FileSystemObject) -> [String] {
	let nds = fileSystemObject as! NDS.Unpacked
	let text = nds.contents.first { $0.name == "text" } as! Folder
	let japanese = text.contents.first { $0.name == "japanese" }! as! MAR.Unpacked
	let dtx = japanese.files.first!.content as! DTX.Unpacked
	return dtx.strings
}
