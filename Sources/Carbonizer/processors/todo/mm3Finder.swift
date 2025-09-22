import BinaryParser

// vertex, texture, animation
//func mm3Finder(_ inputFile: consuming any FileSystemObject, _ parent: Folder) throws -> [any FileSystemObject] {
//	let file: MAR.Unpacked
//	switch inputFile {
//		case let mar as MAR.Unpacked:
//			file = mar
//		case let other:
//			return [other]
//	}
//	
//	// any MAR with an mm3 should be standalone, so we're not skipping any here
//	guard let mm3 = file.files.first?.content as? MM3.Unpacked else {
//		return [file]
//	}
//	
//	let blocklist = [
//		"o02door1_01", // bone -1
//		"o08iwa3_2_01", // bone -1
//		"out03_1", // malformed texture
//		"testman", // malformed texture?
//		"out04_1", // malformed texture?
//		"out09_5", // malformed texture?
//		"room31",
//		"room41",
//		"room42",
//		"room43",
//		"room45",
//		"room50",
//		"room53",
//		"town01b", // malformed texture?
//	]
//	guard !blocklist.contains(file.name) else { return [file] }
//	
//#if os(Windows)
//	let windowsBlocklist = [
//		"map_model_0001",
//		"map_model_0002"
//	]
//	guard !windowsBlocklist.contains(file.name) else { return [file] }
//#endif
//	
////	guard file.name == "cha01a_01" || file.name == "cha01a_30" else { return [file] }
////	guard file.name == "cha01a_02" else { return [file] }
////	guard file.name == "head01a" else { return [file] }
//	
//	// TODO: logprogress
////	print()
////	print(file.name)
//	
//	do {
//		let arc = parent.contents.first { $0.name == mm3.mesh.tableName }! as! MAR.Unpacked
//		
//		guard arc.files.indices.contains(Int(mm3.mesh.index)) else {
//			throw BinaryParserError.indexOutOfBounds(
//				index: Int(mm3.mesh.index),
//				expected: arc.files.indices,
//				whileReading: MM3.self
//			)
//		}
//		
//		let meshData = Datastream(arc.files[Int(mm3.mesh.index)].content as! Datastream) // copy to not modify the original
//		let mesh = try meshData.read(Mesh.Packed.self)
//		
//		guard arc.files.indices.contains(Int(mm3.texture.index)) else {
//			throw BinaryParserError.indexOutOfBounds(
//				index: Int(mm3.texture.index),
//				expected: arc.files.indices,
//				whileReading: MM3.self
//			)
//		}
//		
//		let textureData = Datastream(arc.files[Int(mm3.texture.index)].content as! Datastream) // copy to not modify the original
//		let texture = try textureData.read(Texture.Packed.self)
//		
//		guard arc.files.indices.contains(Int(mm3.animation.index)) else {
//			throw BinaryParserError.indexOutOfBounds(
//				index: Int(mm3.animation.index),
//				expected: arc.files.indices,
//				whileReading: MM3.self
//			)
//		}
//		
//		let animationData = Datastream(arc.files[Int(mm3.animation.index)].content as! Datastream) // copy to not modify the original
//		let animation = try animationData.read(Animation.Packed.self)
//		
//		// TODO: export textures inside the mar file to avoid duplication
//		// TODO: put textures in a textures/ or assets/ folder so theres not a million right at the start
//		let textureFolder = try texture.folder(named: file.name)
//		
//		// no two images in a texture should have the same offset.... right?
//		let textureNames = Dictionary(
//			uniqueKeysWithValues: try texture.imageHeaders.map {
//				// see http://problemkaputt.de/gbatek-ds-3d-texture-attributes.htm
//				switch try $0.info().type {
//					case .twoBits:
//						($0.paletteOffset >> 3, "\(file.name)/\($0.name)")
//					default:
//						($0.paletteOffset >> 4, "\(file.name)/\($0.name)")
//				}
//			}
//		)
//		
////		let usd = try USD(
////			vertexData: vertexData,
////			animationData: animation,
////			modelName: file.name,
////			textureNames: textureNames
////		)
////		
////		let usdFile = BinaryFile(
////			name: file.name + ".usd",
////			metadata: .skipFile,
////			data: Datastream(usd.string().data(using: .utf8)!)
////		)
////		
////		return [file, usdFile, textureFolder]
//		
//		let collada = try Collada(
//			mesh: mesh,
//			animationData: animation,
//			modelName: file.name,
//			textureNames: textureNames
//		)
//		
//		let colladaFile = BinaryFile(
//			name: file.name + ".dae",
//			data: Datastream(collada.asString().data(using: .utf8)!)
//		)
//		
//		return [file, colladaFile, textureFolder]
//	} catch {
//		// ignore for now
//		print(file.name, "failed", error)
//		return [file]
//	}
//}
