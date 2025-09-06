import BinaryParser

func mm3Finder(_ inputFile: consuming any FileSystemObject, _ parent: Folder) throws -> [any FileSystemObject] {
	let file: MAR.Unpacked
	switch inputFile {
		case let mar as MAR.Unpacked:
			file = mar
		case let other:
			return [other]
	}
	
	// any MAR with an mm3 should be standalone, so we're not skipping any here
	guard let mm3 = file.files.first?.content as? MM3.Unpacked else {
		return [file]
	}
	
	let blocklist = [
		"o02door1_01", // bone -1
		"o08iwa3_2_01", // bone -1
		"out03_1", // malformed texture
		"testman", // malformed texture?
		"out04_1", // malformed texture?
		"out09_5", // malformed texture?
		"room31",
		"room41",
		"room42",
		"room43",
		"room45",
		"room50",
		"room53",
		"town01b", // malformed texture?
	]
	guard !blocklist.contains(file.name) else { return [file] }
	
#if os(Windows)
	let windowsBlocklist = [
		"map_model_0001",
		"map_model_0002"
	]
	guard !windowsBlocklist.contains(file.name) else { return [file] }
#endif
	
//	guard file.name == "cha01a_01" || file.name == "cha01a_30" else { return [file] }
//	guard file.name == "cha01a_02" else { return [file] }
//	guard file.name == "head01a" else { return [file] }
	
//	print()
//	print(file.name)
	
	do {
		let arc = parent.contents.first { $0.name == mm3.model.tableName }! as! MAR.Unpacked
		
		guard arc.files.indices.contains(Int(mm3.model.index)) else {
			throw BinaryParserError.indexOutOfBounds(
				index: Int(mm3.model.index),
				expected: arc.files.indices,
				whileReading: MM3.self
			)
		}
		
		let modelData = Datastream(arc.files[Int(mm3.model.index)].content as! Datastream) // copy to not modify the original
		let vertexData = try modelData.read(VertexData.self)
		
		guard arc.files.indices.contains(Int(mm3.texture.index)) else {
			throw BinaryParserError.indexOutOfBounds(
				index: Int(mm3.texture.index),
				expected: arc.files.indices,
				whileReading: MM3.self
			)
		}
		
		let textureData = Datastream(arc.files[Int(mm3.texture.index)].content as! Datastream) // copy to not modify the original
		let texture = try textureData.read(TextureData.self)
		
		guard arc.files.indices.contains(Int(mm3.animation.index)) else {
			throw BinaryParserError.indexOutOfBounds(
				index: Int(mm3.animation.index),
				expected: arc.files.indices,
				whileReading: MM3.self
			)
		}
		
		let animationData = Datastream(arc.files[Int(mm3.animation.index)].content as! Datastream) // copy to not modify the original
		let animation = try animationData.read(AnimationData.self)
		
		
		let textureFolder = try texture.folder(named: file.name)
		
		// no two images in a texture should have the same offset.... right?
		let textureNames = Dictionary(
			uniqueKeysWithValues: try texture.imageHeaders.map {
				// see http://problemkaputt.de/gbatek-ds-3d-texture-attributes.htm
				switch try $0.info().type {
					case .twoBits:
						($0.paletteOffset >> 3, "\(file.name)/\($0.name)")
					default:
						($0.paletteOffset >> 4, "\(file.name)/\($0.name)")
				}
			}
		)
		
		let collada = try Collada(
			vertexData: vertexData,
			animationData: animation,
			modelName: file.name,
			textureNames: textureNames
		)
		
		let colladaFile = BinaryFile(
			name: file.name + ".dae",
			metadata: .skipFile,
			data: Datastream(collada.asString().data(using: .utf8)!)
		)
		
		return [file, colladaFile, textureFolder]
	} catch {
		// ignore for now
		print(file.name, "failed", error)
		return [file]
	}
}
