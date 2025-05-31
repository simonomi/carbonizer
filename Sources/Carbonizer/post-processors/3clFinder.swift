import BinaryParser

func tclFinder(_ inputFile: consuming any FileSystemObject, _ parent: Folder) throws -> [any FileSystemObject] {
	let file: MAR.Unpacked
	switch inputFile {
		case let mar as MAR.Unpacked:
			file = mar
		case let other:
			return [other]
	}
	
	// the only MAR with a 3cl has it as its first file
	guard let tcl = file.files.first?.content as? TCL.Unpacked else {
		return [file]
	}
	
	do {
		var results: [any FileSystemObject] = [file]
		
		for (vivosaurId, vivosaur) in tcl.vivosaurs.enumerated() {
			let animations = vivosaur?.animations ?? []
			for (animationId, vivosaurAnimation) in animations.enumerated() {
				guard let vivosaurAnimation else { continue }
				
				let arc = parent.contents.first { $0.name == vivosaurAnimation.model.tableName }! as! MAR.Unpacked
				
				guard arc.files.indices.contains(Int(vivosaurAnimation.model.index)) else {
					throw BinaryParserError.indexOutOfBounds(
						index: Int(vivosaurAnimation.model.index),
						expected: arc.files.indices,
						whileReading: TCL.self
					)
				}
				
				let modelData = arc.files[Int(vivosaurAnimation.model.index)].content as! Datastream
				let modelStart = modelData.placeMarker()
				let vertexData = try modelData.read(VertexData.self)
				modelData.jump(to: modelStart)
				
				guard arc.files.indices.contains(Int(vivosaurAnimation.texture.index)) else {
					throw BinaryParserError.indexOutOfBounds(
						index: Int(vivosaurAnimation.texture.index),
						expected: arc.files.indices,
						whileReading: TCL.self
					)
				}
				
				let textureData = arc.files[Int(vivosaurAnimation.texture.index)].content as! Datastream
				let textureStart = textureData.placeMarker()
				let texture = try textureData.read(TextureData.self)
				textureData.jump(to: textureStart)
				
				guard arc.files.indices.contains(Int(vivosaurAnimation.animation.index)) else {
					throw BinaryParserError.indexOutOfBounds(
						index: Int(vivosaurAnimation.animation.index),
						expected: arc.files.indices,
						whileReading: TCL.self
					)
				}

				let animationData = arc.files[Int(vivosaurAnimation.animation.index)].content as! Datastream
				let animationStart = animationData.placeMarker()
				let animation = try animationData.read(AnimationData.self)
				animationData.jump(to: animationStart)
				
				let fileName = "vivosaur \(vivosaurId) animation \(animationId)"
				let fileNameWithoutSpaces = fileName.replacing(" ", with: "-")
				
				let textureFolder = try texture.folder(named: fileNameWithoutSpaces)
				
				results.append(textureFolder)
				
				// no two images in a texture should have the same offset.... right?
				let textureNames = Dictionary(
					uniqueKeysWithValues: try texture.imageHeaders.map {
						// see http://problemkaputt.de/gbatek-ds-3d-texture-attributes.htm
						switch try $0.info().type {
							case .twoBits:
								($0.paletteOffset >> 3, "\(fileNameWithoutSpaces)/\($0.name)")
							default:
								($0.paletteOffset >> 4, "\(fileNameWithoutSpaces)/\($0.name)")
						}
					}
				)
				
				let collada = try Collada(
					vertexData: vertexData,
					animationData: animation,
					modelName: fileName,
					textureNames: textureNames
				)
				
				let colladaFile = BinaryFile(
					name: fileName + ".dae",
					data: Datastream(collada.asString().data(using: .utf8)!)
				)
				
				results.append(colladaFile)
			}
		}
		
		return results
	} catch {
		// ignore for now
		print(file.name, "failed", error)
		return [file]
	}
}
