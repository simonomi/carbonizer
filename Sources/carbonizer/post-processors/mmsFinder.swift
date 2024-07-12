import BinaryParser

func mmsFinder(_ file: consuming File, _ parent: Folder) throws -> [any FileSystemObject] {
	guard let mar = file.data as? MAR else { return [file] }
	
//	guard file.name == "particle_drill" else { continue }
	
	if file.name == "info_win.bin" { return [file] } // only has 8 colors in its palette??
	if file.name == "kp_back.bin" { return [file] } // lists 276 as a palette, its a bitmap
	if parent.name == "save_slot", file.name == "back_bot.bin" { return [file] } // lists 71 as a palette, its a bitmap
	if parent.name == "topmenu" { return [file] } // so many bugs in this folder, lets just skip it
	if parent.name == "ui_revive", file.name == "kaseki_401_01.bin" { return [file] } // tries to access out of bounds

	
	var folders = [Folder]()
	
	for mms in mar.files.compactMap({ $0.content as? MMS }) {
//		guard mms.colorPalette.tableName == "cleaning_arc.bin" else { continue }
		
		// color palette notes
		// - first uint32 - 16 or 256 colors
		
		// bitmap notes
		// - first byte - idk
		// - second byte - the length of the file / 32
		//   - unless third byte is 01
		// - third byte - 16 or 256 colors
		
//		print(
//			mms.bitmap.indices
//				.map(String.init)
//				.map { $0.padded(toLength: 4, with: "0") }
//				.joined(separator: "\n")
//		)
		
		var folder = Folder(name: file.name, files: [])
		
		for colorPaletteIndex in mms.colorPalette.indices.map(Int.init) {
			if parent.name == "topmenu", [8, 9].contains(colorPaletteIndex) {
				continue // 8 and 9 aren't palettes... idk what they are
			}
			
			if parent.name == "ui_shop", colorPaletteIndex == 2 {
				continue // only has 8 colors
			}
			
			let colorPaletteArchive = parent.files.first { $0.name == mms.colorPalette.tableName } as! File
			let colorPaletteMAR = colorPaletteArchive.data as! MAR
			
			if colorPaletteIndex > colorPaletteMAR.files.count {
				print(parent.name, file.name)
			}
			
			let colorPaletteFile = colorPaletteMAR.files[colorPaletteIndex]
			let colorPaletteData = colorPaletteFile.content as! Datastream
			colorPaletteData.offset = 0 // multiple files use the same palette
			let colorPalette: SpritePalette
			do {
				colorPalette = try SpritePalette(colorPaletteData)
			} catch {
				throw BinaryParserError.whileReadingFile(parent.name + "/" + file.name, "palette", String(colorPaletteIndex), error)
			}
			
			for bitmapIndex in mms.bitmap.indices.map(Int.init) {
				let bitmapArchive = parent.files.first { $0.name == mms.bitmap.tableName } as! File
				let bitmapMAR = bitmapArchive.data as! MAR
				
				if bitmapIndex > bitmapMAR.files.count {
					print(parent.name, file.name)
				}
				
				let bitmapFile = bitmapMAR.files[bitmapIndex]
				let bitmapData = bitmapFile.content as! Datastream
				bitmapData.offset = 0 // multiple files use the same bitmap
				let spriteBitmap: SpriteBitmap
				do {
					spriteBitmap = try SpriteBitmap(bitmapData)
				} catch {
					throw BinaryParserError.whileReadingFile(parent.name + "/" + file.name, "bitmap", String(bitmapIndex), error)
				}
				
				let bitmap = spriteBitmap.toBitmap(with: colorPalette)
				
				folder.files.append(File(name: "\(file.name) \(colorPaletteIndex)x\(bitmapIndex)", data: bitmap))
			}
		}
		
		folders.append(folder)
	}
	
	return [file] + folders
}
