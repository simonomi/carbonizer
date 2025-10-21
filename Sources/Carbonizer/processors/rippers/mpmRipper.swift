func mpmRipperF(
	_ mpm: inout MPM.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	if environment.imagePaletteFiles == nil {
		environment.imagePaletteFiles = [:]
	}
	
	let paletteTablePath = Array(path.dropLast() + [mpm.palette.tableName])
	environment.imagePaletteFiles![paletteTablePath, default: []].insert(Int(mpm.palette.index))
	
	if environment.imageBitmapFiles == nil {
		environment.imageBitmapFiles = [:]
	}
	
	let bitmapTablePath = Array(path.dropLast() + [mpm.bitmap.tableName])
	environment.imageBitmapFiles![bitmapTablePath, default: []].insert(Int(mpm.bitmap.index))
	
	if environment.bgMapFiles == nil {
		environment.bgMapFiles = [:]
	}
	
	if let bgMap = mpm.bgMap {
		let bgMapTablePath = Array(path.dropLast() + [bgMap.tableName])
		environment.bgMapFiles![bgMapTablePath, default: []].insert(Int(bgMap.index))
	}
	
	let folderPath: [String] = path.dropLast()
	
	let tableName = mpm.palette.tableName
	guard tableName == mpm.bitmap.tableName,
		  (mpm.bgMap?.tableName == nil || mpm.bgMap?.tableName == tableName)
	else {
		todo("paths must match :/")
	}
	
	let imageIndices = Processor.Environment.ImageIndices(
		imageName: path.last!,
		width: mpm.width,
		height: mpm.height,
		paletteIndex: Int(mpm.palette.index),
		bitmapIndex: Int(mpm.bitmap.index),
		bgMapIndex: mpm.bgMap.map { Int($0.index) }
	)
	
	if environment.imageIndices == nil {
		environment.imageIndices = [:]
	}
	
	environment.imageIndices![folderPath, default: [:]][tableName, default: []]
		.insert(imageIndices)
}
