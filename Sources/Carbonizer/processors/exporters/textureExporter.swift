func textureExporterF(
	_ folder: inout Folder,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	guard let foldersWithTextureArchives = environment.foldersWithTextureArchives else {
		throw TextureFoldersNotRipped()
	}
	
	guard foldersWithTextureArchives.contains(path) else { return }
	
	var assets = Folder(name: "assets", metadata: .skipFile, contents: [])
	
	for file in folder.contents {
		guard let mar = file as? MAR.Unpacked else { continue }
		
		var textureFolders: [Folder] = []
		
		for (index, mcm) in mar.files.enumerated() {
			guard let texture = mcm.content as? Texture.Unpacked else { continue }
			
			let name = String(index).padded(toLength: 4, with: "0")
			do {
				textureFolders.append(try texture.folder(named: name))
			} catch {
				// TODO: log properly
				print(path + [mar.name, name])
				print(error)
			}
		}
		
		if textureFolders.isNotEmpty {
			assets.contents.append(
				Folder(
					name: mar.name,
					metadata: .skipFile,
					contents: textureFolders
				)
			)
		}
	}
	
	folder.contents.append(assets)
}

struct TextureFoldersNotRipped: Error, CustomStringConvertible {
	var description: String {
		"textureExporter was run without having ripped the texture folders"
	}
}
