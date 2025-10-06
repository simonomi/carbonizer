import BinaryParser

func modelReparserF(
	_ mar: inout MAR.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	guard try environment.modelTableNames().contains(path) else { return }
	
	let meshFiles = try environment.get(\.meshFiles)
	if let meshIndices = meshFiles[path] {
		for fileIndex in meshIndices {
			guard mar.files.indices.contains(fileIndex) else {
				todo("invalid index")
			}
			
			guard let data = mar.files[fileIndex].content as? Datastream else {
				todo("invalid type")
			}
			
			do {
				// copy to not modify the original
				let packed = try Datastream(data).read(Mesh.Packed.self)
				mar.files[fileIndex].content = try packed.unpacked(configuration: configuration)
			} catch {
				let location = "\(path + [String(fileIndex)]):"
				configuration.log(.warning, location, error)
			}
		}
	}
	
	let textureFiles = try environment.get(\.textureFiles)
	if let textureIndices = textureFiles[path] {
		for fileIndex in textureIndices {
			guard mar.files.indices.contains(fileIndex) else {
				todo("invalid index")
			}
			
			guard let data = mar.files[fileIndex].content as? Datastream else {
				todo("invalid type")
			}
			
			do {
				// copy to not modify the original
				let packed = try Datastream(data).read(Texture.Packed.self)
				mar.files[fileIndex].content = try packed.unpacked(configuration: configuration)
			} catch {
				let location = "\(path + [String(fileIndex)]):"
				configuration.log(.warning, location, error)
			}
		}
	}
	
	let animationFiles = try environment.get(\.animationFiles)
	if let animationIndices = animationFiles[path] {
		for fileIndex in animationIndices {
			guard mar.files.indices.contains(fileIndex) else {
				todo("invalid index")
			}
			
			guard let data = mar.files[fileIndex].content as? Datastream else {
				todo("invalid type")
			}
			
			do {
				// copy to not modify the original
				let packed = try Datastream(data).read(Animation.Packed.self)
				mar.files[fileIndex].content = packed.unpacked(configuration: configuration)
			} catch {
				let location = "\(path + [String(fileIndex)]):"
				configuration.log(.warning, location, error)
			}
		}
	}
}
