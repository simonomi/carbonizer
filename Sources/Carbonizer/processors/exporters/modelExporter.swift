import BinaryParser

func modelExporterF(
	_ folder: inout Folder,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	let modelIndices = try environment.get(\.modelIndices)
	guard let tables = modelIndices[path] else { return }
	
	for file in folder.contents {
		guard let mar = file as? MAR.Unpacked,
			  let indices = tables[mar.name]
		else { continue }
		
		for modelIndices in indices {
			do {
				guard let mesh = mar.files[modelIndices.meshIndex].content as? Mesh.Unpacked else {
					throw MissingComponent.mesh(modelIndices.meshIndex)
				}
				
				let texture = mar.files[modelIndices.textureIndex].content as? Texture.Unpacked
				
				if texture == nil {
					configuration.log(.warning, "textures missing for \(modelIndices.modelName)")
				}
				
				guard let animation = mar.files[modelIndices.animationIndex].content as? Animation.Unpacked else {
					throw MissingComponent.animation(modelIndices.animationIndex)
				}
				
				let textureName = String(modelIndices.textureIndex)
					.padded(toLength: 4, with: "0")
				
				let collada = try Collada(
					mesh: mesh,
					animationData: animation,
					modelName: modelIndices.modelName,
					texturePath: "assets/\(mar.name)/\(textureName)",
					textureNames: try texture?.textureNames()
				)
				
				let colladaFile = BinaryFile(
					name: modelIndices.modelName + ".dae",
					metadata: .skipFile,
					data: Datastream(collada.asString().data(using: .utf8)!)
				)
				
				folder.contents.append(colladaFile)
			} catch {
				let location = "\(path + [modelIndices.modelName]):"
				configuration.log(.warning, location, error)
			}
		}
	}
}

enum MissingComponent: Error, CustomStringConvertible {
	case mesh(Int)
	case texture(Int)
	case animation(Int)
	
	var description: String {
		switch self {
			case .mesh(let index):
				"missing mesh \(index)"
			case .texture(let index):
				"missing texture \(index)"
			case .animation(let index):
				"missing animation \(index)"
		}
	}
}
