func mm3RipperF(
	_ mm3: inout MM3.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	if environment.vertexFiles == nil {
		environment.vertexFiles = [:]
	}
	
	let modelTablePath = Array(path.dropLast() + [mm3.model.tableName])
	environment.vertexFiles![modelTablePath, default: []].append(Int(mm3.model.index))
	
	if environment.textureFiles == nil {
		environment.textureFiles = [:]
	}
	
	let textureTablePath = Array(path.dropLast() + [mm3.texture.tableName])
	environment.textureFiles![textureTablePath, default: []].append(Int(mm3.texture.index))
	
	if environment.animationFiles == nil {
		environment.animationFiles = [:]
	}
	
	let animationTablePath = Array(path.dropLast() + [mm3.animation.tableName])
	environment.animationFiles![animationTablePath, default: []].append(Int(mm3.animation.index))
}
