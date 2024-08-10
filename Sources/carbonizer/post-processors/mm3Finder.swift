import BinaryParser

import Foundation

fileprivate func parseFixed2012(_ fixed: Int32) -> Double {
	Double(fixed) / Double(1 << 12)
}

fileprivate struct Matrix: BinaryConvertible, CustomStringConvertible, Equatable {
	var x: SIMD3<Double>
	var y: SIMD3<Double>
	var z: SIMD3<Double>
	var s: SIMD3<Double>
	
	static let zero = Self(x: .zero, y: .zero, z: .zero, s: .zero)
	
	static let unit = Self(x: SIMD3(1, 0, 0), y: SIMD3(0, 1, 0), z: SIMD3(0, 0, 1), s: .zero)
	
	init(x: SIMD3<Double>, y: SIMD3<Double>, z: SIMD3<Double>, s: SIMD3<Double>) {
		self.x = x
		self.y = y
		self.z = z
		self.s = s
	}
	
	init(_ data: Datastream) throws {
		x = SIMD3(
			parseFixed2012(try data.read(Int32.self)),
			parseFixed2012(try data.read(Int32.self)),
			parseFixed2012(try data.read(Int32.self))
		)
		y = SIMD3(
			parseFixed2012(try data.read(Int32.self)),
			parseFixed2012(try data.read(Int32.self)),
			parseFixed2012(try data.read(Int32.self))
		)
		z = SIMD3(
			parseFixed2012(try data.read(Int32.self)),
			parseFixed2012(try data.read(Int32.self)),
			parseFixed2012(try data.read(Int32.self))
		)
		s = SIMD3(
			parseFixed2012(try data.read(Int32.self)),
			parseFixed2012(try data.read(Int32.self)),
			parseFixed2012(try data.read(Int32.self))
		)
	}
	
	func write(to data: Datawriter) {
		fatalError()
	}
	
	var description: String {
		"[\(format(x)), \(format(y)), \(format(z)), \(format(s))]"
	}
}

fileprivate extension SIMD3<Double> {
	consuming func transformed(by matrix: Matrix) -> Self {
		x * matrix.x + y * matrix.y + z * matrix.z + matrix.s
	}
}

struct Triangle: CustomStringConvertible {
	var firstPoint: SIMD3<Double>
	var secondPoint: SIMD3<Double>
	var thirdPoint: SIMD3<Double>
	
	init(_ firstPoint: SIMD3<Double>, _ secondPoint: SIMD3<Double>, _ thirdPoint: SIMD3<Double>) {
		self.firstPoint = firstPoint
		self.secondPoint = secondPoint
		self.thirdPoint = thirdPoint
	}
	
	var description: String {
		"(\(format(firstPoint)), \(format(secondPoint)), \(format(thirdPoint)))"
	}
}

enum VertexMode {
	case triangle, quadrilateral, triangleStrip, quadrilateralStrip
}

func mm3Finder(_ inputFile: consuming any FileSystemObject, _ parent: Folder) throws -> [any FileSystemObject] {
	let file: MAR
	switch inputFile {
		case let mar as MAR:
			file = mar
		case let other:
			return [other]
	}
	
	// any MAR with an mm3 should be standalone, so we're not skipping any here
	guard let mm3 = file.files.first?.content as? MM3 else {
		return [file]
	}
	
	// cha01a_01: 25, 26, 27
//	guard file.name == "cha01a_01" else { return [file] }
//	guard file.name == "head01a" else { return [file] }
//	guard file.name.hasPrefix("head") else { return [file] }
    
	// fails at implicitly unwrapped optional
//	guard file.name == "o08iwa3_2_01" else { return [file] }

//	guard file.name.hasPrefix("ch") else { return [file] }
//	guard parent.name == "fieldchar" else { return [file] }
	
	let blocklist = ["testman", "out03_1", "out04_1", "out09_5", "room31", "room41", "room42", "room43", "room45", "room50", "room53", "town01b"]
	guard !blocklist.contains(file.name) else { return [file] }
	
//	guard file.name == "room01" else { return [file] }
	guard file.name == "cha01a_04" else { return [file] }
	
//	let blocklist = ["ana_01", "boat_01", "hasigo_01", "mask06", "mask13"]
//	guard !blocklist.contains(file.name) else { return [file] }
	
//	print(file.name)
	
	do {
		let arc = parent.contents.first { $0.name == mm3.model.tableName }! as! MAR
		
		let modelData = arc.files[Int(mm3.model.index)].content as! Datastream
		let modelStart = modelData.placeMarker()
		let vertexData = try modelData.read(VertexData.self)
		modelData.jump(to: modelStart)
		
		let textureData = arc.files[Int(mm3.texture.index)].content as! Datastream
		let textureStart = textureData.placeMarker()
		let texture = try textureData.read(TextureData.self)
		textureData.jump(to: textureStart)
		
		let animationData = arc.files[Int(mm3.animation.index)].content as! Datastream
		let animationStart = animationData.placeMarker()
		let animation = try animationData.read(AnimationData.self)
		animationData.jump(to: animationStart)
		
		var outputFolder = try texture.folder(named: file.name)
		
		let mtlText = texture.imageHeaders
			.map(\.name)
			.map {
				"""
				newmtl \($0)
				map_Kd \(outputFolder.name)/\($0).png
				"""
			}
			.joined(separator: "\n\n")
		
		let mtlData = mtlText.data(using: .utf8)!
		let mtlFile = BinaryFile(name: file.name, fileExtension: "mtl", data: Datastream(mtlData))
		
		outputFolder.contents.append(mtlFile)
		
		// no two images in a texture should have the same offset.... right?
		let textureNames = Dictionary(
			uniqueKeysWithValues: try texture.imageHeaders.map {
				// see http://problemkaputt.de/gbatek-ds-3d-texture-attributes.htm
				switch try $0.info().type {
					case .twoBits:
						($0.paletteOffset >> 3, $0.name)
					default:
						($0.paletteOffset >> 4, $0.name)
				}
			}
		)
		
		let boneTables = animation.keyframes.transforms
			.chunked(exactSize: Int(animation.keyframes.boneCount))
		
		let objFiles = try boneTables.enumerated().map { (frameNumber, boneTable) in
			let obj = try vertexData.obj(
				matrices: Array(boneTable),
				textureNames: textureNames
			)
			
			let mtlFileName = "\(outputFolder.name)/\(file.name)"
			let objData = Datastream(obj.text(mtlFile: mtlFileName).data(using: .utf8)!)
			
			let fileName = "\(file.name) frame \(frameNumber)"
			let objFile = BinaryFile(name: fileName, fileExtension: "obj", data: objData)
			
			return objFile
		}
		
		return [file, outputFolder] + objFiles
    } catch {
		// ignore for now
//		print(file.name, "failed", error)
    }
	
	return [file]
}

//fileprivate func parse4_12(_ fixed: UInt16) -> Double {
//	Double(Int16(bitPattern: fixed)) / Double(1 << 12)
//}

fileprivate func format<B>(_ simd: SIMD3<B>) -> String {
	"(\(simd.x), \(simd.y), \(simd.z))"
}

fileprivate let argumentCountPerCommand: [UInt8: Int] = [0x00: 0, 0x10: 1, 0x11: 0, 0x12: 1, 0x13: 1, 0x14: 1, 0x15: 0, 0x16: 16, 0x17: 12, 0x18: 16, 0x19: 12, 0x1a: 9, 0x1b: 3, 0x1c: 3, 0x20: 1, 0x21: 1, 0x22: 1, 0x23: 2, 0x24: 1, 0x25: 1, 0x26: 1, 0x27: 1, 0x28: 1, 0x29: 1, 0x2a: 1, 0x2b: 1, 0x30: 1, 0x31: 1, 0x32: 1, 0x33: 1, 0x34: 1, 0x40: 1, 0x41: 0, 0x53: 3]

fileprivate let commandNames: [UInt8: String] = [0x00: "NOP", 0x10: "MTX_MODE", 0x11: "MTX_PUSH", 0x12: "MTX_POP", 0x13: "MTX_STORE", 0x14: "MTX_RESTORE", 0x15: "MTX_IDENTITY", 0x16: "MTX_LOAD_4x4", 0x17: "MTX_LOAD_4x3", 0x18: "MTX_MULT_4x4", 0x19: "MTX_MULT_4x3", 0x1A: "MTX_MULT_3x3", 0x1B: "MTX_SCALE", 0x1C: "MTX_TRANS", 0x20: "COLOR", 0x21: "NORMAL", 0x22: "TEXCOORD", 0x23: "VTX_16", 0x24: "VTX_10", 0x25: "VTX_XY", 0x26: "VTX_XZ", 0x27: "VTX_YZ", 0x28: "VTX_DIFF", 0x29: "POLYGON_ATTR", 0x2A: "TEXIMAGE_PARAM", 0x2B: "PLTT_BASE", 0x30: "DIF_AMB", 0x31: "SPE_EMI", 0x32: "LIGHT_VECTOR", 0x33: "LIGHT_COLOR", 0x34: "SHININESS", 0x40: "BEGIN_VTXS", 0x41: "END_VTXS", 0x53: "UNKNOWN 0x53"]
