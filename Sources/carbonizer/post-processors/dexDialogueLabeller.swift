func dexDialogueLabeller(
	_ fileSystemObject: consuming any FileSystemObject,
	dialogue: [UInt32: String],
	configuration: CarbonizerConfiguration
) -> any FileSystemObject {
	switch fileSystemObject {
		case let binaryFile as BinaryFile: binaryFile
		case let file as ProprietaryFile:
			ProprietaryFile(
				name: file.name,
				metadata: file.metadata,
				data: label(file.data, with: dialogue) as any ProprietaryFileData
			)
		case let mar as MAR:
			MAR(
				name: mar.name,
				files: mar.files
					.map {
						MCM(
							compression: $0.compression,
							maxChunkSize: $0.maxChunkSize,
							content: label($0.content, with: dialogue) as any ProprietaryFileData
						)
					}
			)
		case let nds as NDS:
			NDS(
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
					dexDialogueLabeller($0, dialogue: dialogue, configuration: configuration)
				},
				configuration: configuration
			)
		case let folder as Folder:
			Folder(
				name: folder.name,
				contents: folder.contents.map {
					dexDialogueLabeller($0, dialogue: dialogue, configuration: configuration)
				}
			)
		case is PackedMAR, is PackedNDS:
			fatalError("must be run on unpacked data")
		case let fileSystemObject:
			fatalError("unexpected fileSystemObject type: \(type(of: fileSystemObject))")
	}
}

func label<P: ProprietaryFileData>(_ file: P, with dialogue: [UInt32: String]) -> P {
	if let dex = file as? DEX {
		label(dex, with: dialogue) as! P
	} else {
		file
	}
}

func label(_ dex: consuming DEX, with allDialogue: [UInt32: String]) -> DEX {
	DEX(
		commands: dex.commands.map {
			$0.reduce(into: []) { partialResult, command in
				let linesOfDialogue = command.linesOfDialogue()
					.compactMap { allDialogue[UInt32($0)] }
				
				for lineOfDialogue in linesOfDialogue {
					partialResult.append(.comment(lineOfDialogue))
				}
				partialResult.append(command)
			}
		}
	)
}
