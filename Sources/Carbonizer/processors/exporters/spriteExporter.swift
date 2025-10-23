func spriteExporterF(
	_ folder: inout Folder,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	let spriteIndices = try environment.get(\.spriteIndices)
	guard let tables = spriteIndices[path] else { return }
	
	for file in folder.contents {
		guard let mar = file as? MAR.Unpacked,
			  let indices = tables[mar.name]
		else { continue }
		
		for spriteIndices in indices {
			let location = (path + [spriteIndices.spriteName]).joined(separator: "/") + ":"
			
			let animations: [SpriteAnimation.Unpacked?] = spriteIndices.animationIndices.map {
				if let content = mar.files[safely: $0]?.content,
				   let animation = content as? SpriteAnimation.Unpacked
				{
					return animation
				} else {
					configuration.log(.warning, location, "missing sprite animation \(.red)\($0)\(.normal)")
					
					return nil
				}
			}
			
			let palettes: [SpritePalette.Unpacked?] = spriteIndices.paletteIndices.map {
				if let content = mar.files[safely: $0]?.content,
				   let palette = content as? SpritePalette.Unpacked
				{
					return palette
				} else {
					configuration.log(.warning, location, "missing sprite palette \(.red)\($0)\(.normal)")
					
					return nil
				}
			}
			
			let bitmaps: [SpriteBitmap.Unpacked?] = spriteIndices.bitmapIndices.map {
				if let content = mar.files[safely: $0]?.content,
				   let bitmap = content as? SpriteBitmap.Unpacked
				{
					return bitmap
				} else {
					configuration.log(.warning, location, "missing sprite bitmap \(.red)\($0)\(.normal)")
					
					return nil
				}
			}
			
			for (index, animation) in animations.enumerated() {
				guard let animation else { continue }
				
				do {
					let bmps = try animation.frames(palettes: palettes, bitmaps: bitmaps)
					
					let files = bmps
						.enumerated()
						.map {
							ProprietaryFile(
								name: spriteIndices.spriteName + " animation \(index) frame \($0)",
								metadata: .skipFile,
								data: $1
							)
						}
					
					folder.contents.append(contentsOf: files)
				} catch {
					configuration.log(.warning, location, "animation \(index):", error)
				}
			}
		}
	}
}
