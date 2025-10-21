func tclRipperF(
	_ tcl: inout TCL.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	if environment.meshFiles == nil {
		environment.meshFiles = [:]
	}
	
	if environment.textureFiles == nil {
		environment.textureFiles = [:]
	}
	
	if environment.foldersWithTextureArchives == nil {
		environment.foldersWithTextureArchives = []
	}
	
	if environment.modelAnimationFiles == nil {
		environment.modelAnimationFiles = [:]
	}
	
	if environment.modelIndices == nil {
		environment.modelIndices = [:]
	}
	
	for (vivosaurID, vivosaur) in tcl.vivosaurs.enumerated() {
		guard let vivosaur else { continue }
		
		for (animationID, animation) in vivosaur.animations.enumerated() {
			guard let animation else { continue }
			
			let meshTablePath = Array(path.dropLast(2) + [animation.mesh.tableName])
			environment.meshFiles![meshTablePath, default: []].insert(Int(animation.mesh.index))
			
			let textureTablePath = Array(path.dropLast(2) + [animation.texture.tableName])
			environment.textureFiles![textureTablePath, default: []].insert(Int(animation.texture.index))
			environment.foldersWithTextureArchives!.insert(path.dropLast())
			
			let animationTablePath = Array(path.dropLast(2) + [animation.animation.tableName])
			environment.modelAnimationFiles![animationTablePath, default: []].insert(Int(animation.animation.index))
			
			let folderPath: [String] = path.dropLast(2)
			
			let tableName = animation.mesh.tableName
			guard tableName == animation.texture.tableName,
				  tableName == animation.animation.tableName
			else {
				todo("paths must match :/")
			}
			
			let modelIndices = Processor.Environment.ModelIndices(
				modelName: "vivosaur \(vivosaurID) animation \(animationID)",
				meshIndex: Int(animation.mesh.index),
				textureIndex: Int(animation.texture.index),
				animationIndex: Int(animation.animation.index)
			)
			
			environment.modelIndices![folderPath, default: [:]][tableName, default: []]
				.insert(modelIndices)
		}
	}
}
