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
	
	if environment.animationFiles == nil {
		environment.animationFiles = [:]
	}
	
	for vivosaur in tcl.vivosaurs {
		guard let vivosaur else { continue }
		
		for animation in vivosaur.animations {
			guard let animation else { continue }
			
			let meshTablePath = Array(path.dropLast(2) + [animation.mesh.tableName])
			environment.meshFiles![meshTablePath, default: []].insert(Int(animation.mesh.index))
			
			let textureTablePath = Array(path.dropLast(2) + [animation.texture.tableName])
			environment.textureFiles![textureTablePath, default: []].insert(Int(animation.texture.index))
			
			let animationTablePath = Array(path.dropLast(2) + [animation.animation.tableName])
			environment.animationFiles![animationTablePath, default: []].insert(Int(animation.animation.index))
		}
	}
}
