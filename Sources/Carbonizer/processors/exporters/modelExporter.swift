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
					throw MissingMesh(index: modelIndices.meshIndex)
				}
				
				let texture = mar.files[modelIndices.textureIndex].content as? Texture.Unpacked
				
				if texture == nil {
					configuration.log(.warning, "textures missing for \(modelIndices.modelName)")
				}
				
				let animation = mar.files[modelIndices.animationIndex].content as? Animation.Unpacked
				
				if animation == nil {
					configuration.log(.warning, "animation \(modelIndices.animationIndex) missing for \(modelIndices.modelName)")
				}
				
				let textureName = String(modelIndices.textureIndex)
					.padded(toLength: 4, with: "0")
				
				var textureNames: [UInt32: String]? = nil
				var texturesHaveTranslucency: [String: Bool]? = nil
				do {
					textureNames = try texture?.textureNames()
					texturesHaveTranslucency = try texture?.texturesHaveTranslucency()
				} catch {
					let location = (path + [modelIndices.modelName]).joined(separator: "/") + ":"
					configuration.log(.warning, location, "textures missing:", error)
				}
				
				let usd = try USD(
					mesh: mesh,
					animationData: animation,
					modelName: modelIndices.modelName,
					texturePath: "assets/\(mar.name)/\(textureName)",
					textureNames: textureNames,
					texturesHaveTranslucency: texturesHaveTranslucency
				)
				
				let usdFile = BinaryFile(
					name: modelIndices.modelName + ".usda",
					metadata: .skipFile,
					data: usd.string().data(using: .utf8)!
				)
				
				folder.contents.append(usdFile)
			} catch {
				let location = (path + [modelIndices.modelName]).joined(separator: "/") + ":"
				configuration.log(.warning, location, error)
			}
		}
	}
}

struct MissingMesh: Error, CustomStringConvertible {
	var index: Int
	
	var description: String {
		"missing mesh \(index)"
	}
}
