func dmgRipper(_ fileSystemObject: any FileSystemObject) -> [UInt32: String] {
	switch fileSystemObject {
		case is BinaryFile, is MAR.Packed, is NDS.Packed:
			[:]
		case let file as ProprietaryFile:
			ripDMGs(file.data)
		case let mar as MAR.Unpacked:
			mar.files.map(\.content).map(ripDMGs).forciblyMerged()
		case let nds as NDS.Unpacked:
			nds.contents.map(dmgRipper).forciblyMerged()
		case let folder as Folder:
			folder.contents.map(dmgRipper).forciblyMerged()
		default:
			fatalError("unexpected fileSystemObject type: \(type(of: fileSystemObject))")
	}
}

fileprivate func ripDMGs(_ data: any ProprietaryFileData) -> [UInt32: String] {
	guard let dmg = data as? DMG.Unpacked else { return [:] }
	
	return dmg.strings.reduce(into: [:]) { partialResult, string in
		partialResult[string.index] = string.string
	}
}

fileprivate extension [[UInt32: String]] {
	func forciblyMerged() -> [UInt32: String] {
		reduce([:]) { partialResult, dialogue in
			partialResult.mergingIgnoringDuplicates(dialogue)
		}
	}
}
