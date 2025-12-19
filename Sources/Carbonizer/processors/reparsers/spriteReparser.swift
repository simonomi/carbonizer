import BinaryParser

func spriteReparserF(
	_ mar: inout MAR.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	guard try environment.spriteTableNames().contains(path) else { return }
	
	// TODO: there are TONS of conflicting indices, manually resolve some ?
	
	let animationFiles = try environment.get(\.spriteAnimationFiles)
	if let animationIndices = animationFiles[path] {
		for fileIndex in animationIndices {
			do {
				guard mar.files.indices.contains(fileIndex) else {
					throw ReparserError.invalidIndex(fileIndex, for: "sprite animation")
				}
				
				guard let bytes = mar.files[fileIndex].content as? ByteSlice else {
					throw ReparserError.invalidType(fileIndex, for: "sprite animation")
				}
				
				var data = Datastream(bytes)
				let packed = try data.read(SpriteAnimation.Packed.self)
				mar.files[fileIndex].content = packed.unpacked(configuration: configuration)
			} catch {
				let location = (path + [String(fileIndex)]).joined(separator: "/") + ":"
				configuration.log(.warning, location, error)
			}
		}
	}
	
	let paletteFiles = try environment.get(\.spritePaletteFiles)
	if let paletteIndices = paletteFiles[path] {
		for fileIndex in paletteIndices {
			do {
				guard mar.files.indices.contains(fileIndex) else {
					throw ReparserError.invalidIndex(fileIndex, for: "sprite palette")
				}
				
				guard let bytes = mar.files[fileIndex].content as? ByteSlice else {
					throw ReparserError.invalidType(fileIndex, for: "sprite palette")
				}
				
				var data = Datastream(bytes)
				let packed = try data.read(SpritePalette.Packed.self)
				mar.files[fileIndex].content = packed.unpacked(configuration: configuration)
			} catch {
				let location = (path + [String(fileIndex)]).joined(separator: "/") + ":"
				configuration.log(.warning, location, error)
			}
		}
	}
	
	let bitmapFiles = try environment.get(\.spriteBitmapFiles)
	if let bitmapIndices = bitmapFiles[path] {
		for fileIndex in bitmapIndices {
			do {
				guard mar.files.indices.contains(fileIndex) else {
					throw ReparserError.invalidIndex(fileIndex, for: "sprite bitmap")
				}
				
				guard let bytes = mar.files[fileIndex].content as? ByteSlice else {
					throw ReparserError.invalidType(fileIndex, for: "sprite bitmap")
				}
				
				var data = Datastream(bytes)
				let packed = try data.read(SpriteBitmap.Packed.self)
				mar.files[fileIndex].content = packed.unpacked(configuration: configuration)
			} catch {
				let location = (path + [String(fileIndex)]).joined(separator: "/") + ":"
				configuration.log(.warning, location, error)
			}
		}
	}
}
