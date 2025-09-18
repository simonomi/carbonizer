func dexDialogueSaver(
	_ fileSystemObject: consuming any FileSystemObject,
	updatedDialogue: [UInt32: String],
	configuration: Carbonizer.Configuration
) -> any FileSystemObject {
	switch fileSystemObject {
		case let binaryFile as BinaryFile: binaryFile
		case let file as ProprietaryFile:
			ProprietaryFile(
				name: file.name,
				metadata: file.metadata,
				data: save(file.data, with: updatedDialogue, fileName: file.name) as any ProprietaryFileData
			)
		case let mar as MAR.Unpacked:
			MAR.Unpacked(
				name: mar.name,
				files: mar.files
					.enumerated()
					.map { (index, mcm) in
						MCM.Unpacked(
							compression: mcm.compression,
							maxChunkSize: mcm.maxChunkSize,
							huffmanCompressionInfo: mcm.huffmanCompressionInfo,
							content: save(
								mcm.content,
								with: updatedDialogue,
								fileName: mar.files.count == 1 ? mar.name : "\(mar.name)/\(index)"
							) as any ProprietaryFileData
						)
					}
			)
		case let nds as NDS.Unpacked:
			NDS.Unpacked(
				name: nds.name,
				header: nds.header,
				arm9: nds.arm9,
				arm9OverlayTable: nds.arm9OverlayTable,
				arm9Overlays: nds.arm9Overlays,
				arm7: nds.arm7,
				arm7OverlayTable: nds.arm7OverlayTable,
				arm7Overlays: nds.arm7Overlays,
				iconBanner: nds.iconBanner,
				contents: nds.contents.map {
					dexDialogueSaver($0, updatedDialogue: updatedDialogue, configuration: configuration)
				}
			)
		case let folder as Folder:
			Folder(
				name: folder.name,
				metadata: folder.metadata,
				contents: folder.contents.map {
					dexDialogueSaver($0, updatedDialogue: updatedDialogue, configuration: configuration)
				}
			)
		case let packedMAR as MAR.Packed: packedMAR
		case let packedNDS as NDS.Packed: packedNDS
		case let fileSystemObject:
			fatalError("unexpected fileSystemObject type: \(type(of: fileSystemObject))")
	}
}

fileprivate func save<File: ProprietaryFileData>(
	_ file: File,
	with updatedDialogue: [UInt32: String],
	fileName: String
) -> File {
	if let dmg = file as? DMG.Unpacked {
		save(dmg, with: updatedDialogue, fileName: fileName) as! File
	} else {
		file
	}
}

fileprivate func save(
	_ dmg: consuming DMG.Unpacked,
	with updatedDialogue: [UInt32: String],
	fileName: String
) -> DMG.Unpacked {
	for index in dmg.strings.indices where updatedDialogue.keys.contains(dmg.strings[index].index) {
		if dmg.strings[index].string != updatedDialogue[dmg.strings[index].index]! {
			print("updating dialogue \(dmg.strings[index].index) in \(fileName)")
			dmg.strings[index].string = updatedDialogue[dmg.strings[index].index]!
		}
	}
	
	return dmg
}
