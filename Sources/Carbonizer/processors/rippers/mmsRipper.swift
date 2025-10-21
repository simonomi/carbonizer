func mmsRipperF(
	_ mms: inout MMS.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	if environment.spriteAnimationFiles == nil {
		environment.spriteAnimationFiles = [:]
	}
	
	let animationTablePath = Array(path.dropLast() + [mms.animations.tableName])
	for index in mms.animations.indices {
		environment.spriteAnimationFiles![animationTablePath, default: []].insert(Int(index))
	}
	
	if environment.spritePaletteFiles == nil {
		environment.spritePaletteFiles = [:]
	}
	
	let paletteTablePath = Array(path.dropLast() + [mms.palettes.tableName])
	for index in mms.palettes.indices {
		environment.spritePaletteFiles![paletteTablePath, default: []].insert(Int(index))
	}
	
	if environment.spriteBitmapFiles == nil {
		environment.spriteBitmapFiles = [:]
	}
	
	let bitmapTablePath = Array(path.dropLast() + [mms.bitmaps.tableName])
	for index in mms.bitmaps.indices {
		environment.spriteBitmapFiles![bitmapTablePath, default: []].insert(Int(index))
	}
	
	let folderPath: [String] = path.dropLast()
	
	let tableName = mms.animations.tableName
	guard tableName == mms.palettes.tableName,
		  tableName == mms.bitmaps.tableName
	else {
		todo("paths must match :/")
	}
	
	let spriteIndices = Processor.Environment.SpriteIndices(
		spriteName: path.last!,
		animationIndices: mms.animations.indices.map(Int.init),
		paletteIndices: mms.palettes.indices.map(Int.init),
		bitmapIndices: mms.bitmaps.indices.map(Int.init)
	)
	
	if environment.spriteIndices == nil {
		environment.spriteIndices = [:]
	}
	
	environment.spriteIndices![folderPath, default: [:]][tableName, default: []]
		.insert(spriteIndices)
}
