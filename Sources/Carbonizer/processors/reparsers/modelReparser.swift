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
			do {
				guard mar.files.indices.contains(fileIndex) else {
					throw ReparserError.invalidIndex(fileIndex, for: "mesh")
				}
				
				guard var data = mar.files[fileIndex].content as? Datastream else {
					throw ReparserError.invalidType(fileIndex, for: "mesh")
				}
				
				let packed = try data.read(Mesh.Packed.self)
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
			do {
				guard mar.files.indices.contains(fileIndex) else {
					throw ReparserError.invalidIndex(fileIndex, for: "texture")
				}
				
				guard var data = mar.files[fileIndex].content as? Datastream else {
					throw ReparserError.invalidType(fileIndex, for: "texture")
				}
				
				let packed = try data.read(Texture.Packed.self)
				mar.files[fileIndex].content = try packed.unpacked(configuration: configuration)
			} catch {
				let location = "\(path + [String(fileIndex)]):"
				configuration.log(.warning, location, error)
			}
		}
	}
	
	let animationFiles = try environment.get(\.modelAnimationFiles)
	if let animationIndices = animationFiles[path] {
		for fileIndex in animationIndices {
			do {
				guard mar.files.indices.contains(fileIndex) else {
					throw ReparserError.invalidIndex(fileIndex, for: "model animation")
				}
				
				guard var data = mar.files[fileIndex].content as? Datastream else {
					throw ReparserError.invalidType(fileIndex, for: "model animation")
				}
				
				let packed = try data.read(Animation.Packed.self)
				mar.files[fileIndex].content = packed.unpacked(configuration: configuration)
			} catch {
				let location = "\(path + [String(fileIndex)]):"
				configuration.log(.warning, location, error)
			}
		}
	}
}
