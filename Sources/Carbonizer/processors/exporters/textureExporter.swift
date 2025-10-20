func textureExporterF(
	_ folder: inout Folder,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	let foldersWithTextureArchives = try environment.get(\.foldersWithTextureArchives)
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
				let location = (path + [mar.name, name]).joined(separator: "/") + ":"
				configuration.log(.warning, location, error)
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
