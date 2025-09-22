func mm3RipperF(
	_ mm3: inout MM3.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	if environment.vertexFiles == nil {
		environment.vertexFiles = [:]
	}
	
	let modelTablePath = Array(path.dropLast() + [mm3.mesh.tableName])
	environment.vertexFiles![modelTablePath, default: []].insert(Int(mm3.mesh.index))
	
	if environment.textureFiles == nil {
		environment.textureFiles = [:]
	}
	
	let textureTablePath = Array(path.dropLast() + [mm3.texture.tableName])
	environment.textureFiles![textureTablePath, default: []].insert(Int(mm3.texture.index))
	
	if environment.animationFiles == nil {
		environment.animationFiles = [:]
	}
	
	let animationTablePath = Array(path.dropLast() + [mm3.animation.tableName])
	environment.animationFiles![animationTablePath, default: []].insert(Int(mm3.animation.index))
}
