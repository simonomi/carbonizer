import BinaryParser

func imageReparserF(
	_ mar: inout MAR.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	guard try environment.imageTableNames().contains(path) else { return }
	
	let paletteFiles = try environment.get(\.paletteFiles)
	if let paletteIndices = paletteFiles[path] {
		for fileIndex in paletteIndices {
			guard mar.files.indices.contains(fileIndex) else {
				todo("invalid index")
			}
			
			guard let data = mar.files[fileIndex].content as? Datastream else {
				todo("invalid type")
			}
			
			do {
				// copy to not modify the original
				let packed = try Datastream(data).read(Palette.Packed.self)
				mar.files[fileIndex].content = packed.unpacked(configuration: configuration)
			} catch {
				let location = (path + [String(fileIndex)]).joined(separator: "/") + ":"
				configuration.log(.warning, location, error)
			}
		}
	}
	
	// bitmaps dont need to be reparsed, since they're literally just a list of indices
	// i *would* parse them anyway into a nicer format, but we don't know here how big the
	// color palette is so we can't
	
//	let bgMapFiles = try environment.get(\.bgMapFiles)
//	if let bgMapIndices = bgMapFiles[path] {
//		for fileIndex in bgMapIndices {
//			guard mar.files.indices.contains(fileIndex) else {
//				todo("invalid index")
//			}
//			
//			guard let data = mar.files[fileIndex].content as? Datastream else {
//				todo("invalid type")
//			}
//			
//			do {
//				// copy to not modify the original
//				let packed = try Datastream(data).read(BGMap.Packed.self)
//				mar.files[fileIndex].content = packed.unpacked(configuration: configuration)
//			} catch {
//				let location = "\(path + [String(fileIndex)]):"
//				configuration.log(.warning, location, error)
//			}
//		}
//	}
}
