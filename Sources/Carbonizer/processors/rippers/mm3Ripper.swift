func mm3RipperF(
	_ mm3: inout MM3.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	if environment.meshFiles == nil {
		environment.meshFiles = [:]
	}
	
	let meshTablePath = Array(path.dropLast() + [mm3.mesh.tableName])
	environment.meshFiles![meshTablePath, default: []].insert(Int(mm3.mesh.index))
	
	if environment.textureFiles == nil {
		environment.textureFiles = [:]
	}
	
	if environment.foldersWithTextureArchives == nil {
		environment.foldersWithTextureArchives = []
	}
	
	let textureTablePath = Array(path.dropLast() + [mm3.texture.tableName])
	environment.textureFiles![textureTablePath, default: []].insert(Int(mm3.texture.index))
	environment.foldersWithTextureArchives!.insert(path.dropLast())
	
	if environment.animationFiles == nil {
		environment.animationFiles = [:]
	}
	
	let animationTablePath = Array(path.dropLast() + [mm3.animation.tableName])
	environment.animationFiles![animationTablePath, default: []].insert(Int(mm3.animation.index))
	
	let folderPath: [String] = path.dropLast()
	
	let tableName = mm3.mesh.tableName
	guard tableName == mm3.texture.tableName,
		  tableName == mm3.animation.tableName
	else {
		todo("paths must match :/")
	}
	
	let modelIndices = Processor.Environment.ModelIndices(
		modelName: path.last!,
		meshIndex: Int(mm3.mesh.index),
		textureIndex: Int(mm3.texture.index),
		animationIndex: Int(mm3.animation.index)
	)
	
	if environment.modelIndices == nil {
		environment.modelIndices = [:]
	}
	
	environment.modelIndices![folderPath, default: [:]][tableName, default: []]
		.insert(modelIndices)
}
