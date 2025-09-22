import BinaryParser

// animations, palettes, bitmaps
func mmsFinder(_ inputFile: consuming any FileSystemObject, _ parent: Folder) throws -> [any FileSystemObject] {
	let file: MAR.Unpacked
	switch inputFile {
		case let mar as MAR.Unpacked:
			file = mar
		case let other:
			return [other]
	}
	
//	guard file.name == "particle_drill" else { continue }
	
	if file.name == "info_win.bin" { return [file] } // only has 8 colors in its palette??
	if file.name == "kp_back.bin" { return [file] } // lists 276 as a palette, its a bitmap
	if parent.name == "save_slot", file.name == "back_bot.bin" { return [file] } // lists 71 as a palette, its a bitmap
	if parent.name == "topmenu" { return [file] } // so many bugs in this folder, lets just skip it
	if parent.name == "ui_revive", file.name == "kaseki_401_01.bin" { return [file] } // tries to access out of bounds
	if file.name == "hit_little.bin" { return [file] } // has bitmaps index 3 4 5 6 but only has 1?
	if parent.name == "ui_shop", file.name == "cont_rbot.bin" { return [file] } // 1st palette is malformed
	
//	guard parent.name == "battle_creature" else {
//	guard file.name == "mike_test.bin" else {
//	guard file.name == "cont_rbot.bin" else {
//	guard file.name == "new_x_ray.bin" else {
//	guard file.name == "gaogao.bin" else {
//	guard file.name == "root_menu.bin" else {
//	guard file.name == "fld_name0.bin" else {
//	guard file.name == "fld_text_frame.bin" else {
//	guard file.name == "sandglass.bin" else {
//	guard file.name == "kp_back_ver2.bin" else {
//		return [file]
//	}
	
	var folders = [Folder]()
	
	for mms in file.files.compactMap({ $0.content as? MMS.Unpacked }) {
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
		
		let animationArchive = parent.contents.first { $0.name == mms.animation.tableName } as! MAR.Unpacked
		
		precondition(mms.animation.indices.first == 0)
		
		var folder = Folder(
			name: file.name + " sprite",
			metadata: .skipFile,
			contents: []
		)
		
		// TODO: temp skip 0
		for animationIndex in mms.animation.indices.map(Int.init).dropFirst() {
			if parent.name == "ui_shop", file.name == "hold_cursor.bin", animationIndex == 1 { continue } // 1st palette is malformed
			
			// TODO: logprogress
//			print("\(parent.name)/\(file.name)")
			
			let colorPaletteArchive = parent.contents.first { $0.name == mms.colorPalette.tableName } as! MAR.Unpacked
			
			let palettes: [SpritePalette?] = try mms.colorPalette.indices.map { colorPaletteIndex in
				if parent.name == "topmenu", [8, 9].contains(colorPaletteIndex) {
					return nil // 8 and 9 aren't palettes... idk what they are
				}
				
				if parent.name == "ui_shop", colorPaletteIndex == 2 {
					return nil // only has 8 colors
				}
				
				let colorPaletteFile = colorPaletteArchive.files[Int(colorPaletteIndex)]
				let colorPaletteData = Datastream(colorPaletteFile.content as! Datastream) // copy so as not to modify the original
				
				do {
					return try SpritePalette(colorPaletteData)
				} catch {
					throw BinaryParserError.whileReadingFile(
						parent.name + "/" + file.name,
//						notes: "palette \(colorPaletteIndex)",
						error
					)
				}
				
			}
			
			let bitmapArchive = parent.contents.first { $0.name == mms.bitmap.tableName } as! MAR.Unpacked
			
			let bitmaps: [SpriteBitmap] = try mms.bitmap.indices.map { bitmapIndex in
				let bitmapFile = bitmapArchive.files[Int(bitmapIndex)]
				let bitmapData = Datastream(bitmapFile.content as! Datastream) // copy so as not to modify the original
				
				do {
					return try SpriteBitmap(bitmapData)
				} catch {
					throw BinaryParserError.whileReadingFile(
						parent.name + "/" + file.name,
//						notes: "bitmap \(bitmapIndex)",
						error
					)
				}
			}
			
			let animationFile = animationArchive.files[animationIndex]
			let animationData = Datastream(animationFile.content as! Datastream) // copy so as not to modify the original
			
			let frames: [Bitmap]
			do {
				let animation = try animationData.read(SpriteAnimation.self)
//				print(prettify(animation.commands))
				frames = try animation.frames(palettes: palettes, bitmaps: bitmaps)
			} catch {
				throw BinaryParserError.whileReadingFile(
					parent.name + "/" + file.name,
//					notes: "animation \(animationIndex)",
					error
				)
			}
			
			if frames.count == 1 {
				folder.contents.append(ProprietaryFile(
					name: "\(file.name) sprite \(animationIndex)",
					data: frames[0]
				))
			} else {
				for (frameIndex, bitmap) in frames.enumerated() {
					folder.contents.append(ProprietaryFile(
						name: "\(file.name) sprite \(animationIndex) frame \(frameIndex)",
						data: bitmap
					))
				}
			}
			
			
			
			// transform notes
			//   256 0 0 256    upright
			//   0 256 -256 0   90° clockwise
			//   -256 0 0 -256  upside down
			//   0 -256 256 0   90° counterclockwise
			
			//    X  Y
			// {  1  0 }
			// {  0  1 }
			
			//    X  Y
			// {  0  1 }
			// { -1  0 }
			
			//    X  Y
			// { -1  0 }
			// {  0 -1 }
			
			//    X  Y
			// {  0 -1 }
			// {  1  0 }
			
			
//			if case .unknown(command: 7, argument: let arg) = commands.last! {
////				print(file.name, commands.last!, "0x" + hex(animationData.offset / 2 - 1))
//				
//				var oks = [Int]()
//				
//				let flag = animationData.placeMarker()
//				for len in 0..<15 {
//					animationData.jump(to: flag)
//					
//					animationData.jump(bytes: len * 2)
//					
//					var rest = [Command]()
//					repeat {
//						rest.append(try animationData.read(Command.self))
//					} while !rest.last!.shouldStop
//					
//					if !rest.contains(where: \.isMalformed) {
//						oks.append(len)
//					}
//				}
//				
//				animationData.jump(to: flag)
//				print(oks.first!, file.name, commands.last!)
//				
////				if oks.contains(Int(arg)) {
////					print(arg, "\(.green)true\(.normal)", file.name)
////				} else {
////					print(arg, "\(.red)false\(.normal)", file.name)
////				}
			}
		
		if folder.contents.isNotEmpty {
			folders.append(folder)
		}
	}
	
	return [file] + folders
}

func prettify(_ commands: [SpriteAnimation.Command]) -> String {
	var output = ""
	for command in commands {
		output += command.description
		switch command {
			case .commit, .quit, .unknown:
				output += "\n"
			default:
				output += ", "
		}
	}
	return output
}
