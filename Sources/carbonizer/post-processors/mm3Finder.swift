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
	
	// cha01a_01: 25, 26, 27
	guard file.name == "cha01a_01" else { return [file] }
//	guard file.name == "head01a" else { return [file] }
    
	// fails at implicitly unwrapped optional
//	guard file.name == "o08iwa3_2_01" else { return [file] }

//	guard file.name.hasPrefix("ch") else { return [file] }
//	guard parent.name == "fieldchar" else { return [file] }

//	let blocklist = ["ana_01", "boat_01", "hasigo_01", "mask06", "mask13"]
//	guard !blocklist.contains(file.name) else { return [file] }
	
//	print(file.name)
	
	do {
		for mm3 in file.files.compactMap({ $0.content as? MM3 }) {
			//		print(file.name)
			//		print("mm3", mm3.model, mm3.animation, mm3.texture)
			let arc = parent.contents.first { $0.name == mm3.model.tableName }! as! MAR
			
			
			
			let textureData = arc.files[Int(mm3.texture.index)].content as! Datastream
			let textureStart = textureData.placeMarker()
			let texture = try textureData.read(TextureData.self)
			textureData.jump(to: textureStart)
			
			return [file, try texture.folder(named: file.name)]
			
//			print(texture)
			
			//		let animationData = ((arc.data as! MAR).files[Int(mm3.entry2.index)].content as! Datastream).bytes
			//		let animation = Datastream(animationData)
			//
			//		animation.jump(bytes: 0x10)
			//		if try! animation.read(UInt32.self) != 0 {
			//			print(file.name)
			//		}
			//
			//		animation.jump(bytes: 0x20)
			//		if try! animation.read(UInt32.self) != 0 {
			//			print(file.name)
			//		}
			//
			//		exit(0)
			
//			let modelData = arc.files[Int(mm3.model.index)].content as! Datastream
//			let start = modelData.placeMarker()
//			let vertexData = try modelData.read(VertexData.self)
//			modelData.jump(to: start)
			
			// copy so theres no side effects
//            let commandData = Datastream(vertexData.commands)
//            let commands = try commandData.readCommands()
//            for command in commands {
//                print(command)
//            }
            
//			let obj = try vertexData.obj()
//			
//			let objData = Datastream(obj.text().data(using: .utf8)!)
//			
//			let objFile = BinaryFile(name: file.name, fileExtension: "obj", data: objData)
//			
//			return [file, objFile]
			
//            let filePath = URL(filePath: "/Users/simonomi/Desktop/cha01a_01.obj")
//            try obj.text().write(to: filePath, atomically: false, encoding: .utf8)
			
//			let animationData = arc.files[Int(mm3.animation.index)].content as! Datastream
//			let animationStart = animationData.placeMarker()
//			let animation = try animationData.read(AnimationData.self)
//			animationData.jump(to: animationStart)
//			
//			let boneTables = animation.keyframes.transforms
//				.chunked(exactSize: Int(animation.keyframes.boneCount))
//			
//			let frames = try boneTables.enumerated().map { (frameNumber, boneTable) in
//				let obj = try vertexData.obj(using: Array(boneTable))
//				
//				let objData = Datastream(obj.text().data(using: .utf8)!)
//				
//				let fileName = "\(file.name) frame \(frameNumber)"
//				let objFile = BinaryFile(name: fileName, fileExtension: "obj", data: objData)
//				
//				return objFile
//			}
//			
//			return [file] + frames
			
			
//            if animation.unknown3 != 0 {
//                print(file.name, animation.unknown2Size, animation.unknown3)
//            }
			
			//		let modelStart = model.placeMarker()
			//
			////		print(file.name, mm3.model.index)
			//
			//		let start = try! model.read(UInt32.self)
			//		precondition(start == 0x20000)
			//
			//		let commandsOffset = try! model.read(UInt32.self)
			//		precondition(commandsOffset == 0x28)
			//
			//		let commandsLength = try! model.read(UInt32.self)
			//		let boneTableLength = try! model.read(UInt32.self)
			//		let modelNamesLength = try! model.read(UInt32.self)
			//
			//		let fourteen = try! model.read(UInt32.self)
			////		print(fourteen)
			////		guard fourteen == 3 else { continue }
			//
			//		// no clue what this number means but when its 0 its all funky
			//		let eighteen = try! model.read(UInt32.self)
			//		guard eighteen != 0 else { continue }
			//
			//		let oneC = try! model.read(UInt32.self)
			////		guard oneC == 0x3 else { continue }
			//
			//		let twenty = try! model.read(UInt32.self)
			////		guard twenty == 0x3C else { continue }
			//
			//		let twentyFour = try! model.read(UInt32.self)
			//
			////		model.jump(to: modelStart + 0x28)
			//
			//		model.jump(to: modelStart + 0x28 + commandsLength)
			//
			//		let numberOfBones = try model.read(UInt32.self)
			//
			//		let boneTable = try (0..<numberOfBones).map { _ in
			//			let name = try model.read(String.self, length: 16)
			//			let matrix = try model.read(Matrix.self)
			//			return (name: name, matrix: matrix)
			//		}
			//
			//		print(
			//			boneTable
			//				.map(\.name)
			//				.map {
			//					$0.reversed()
			//						.drop { $0 == "\u{0}" }
			//						.reversed()
			//				}
			//				.map(String.init)
			//		)
			//		print(boneTable.map { "\($0.name) \($0.matrix)" }.joined(separator: "\n"))
			//
			//
			//		model.jump(to: modelStart + 0x28)
			
			
			
			
			
			
			//		return [file]
			
			//		var mtxRestores = [UInt32]()
			//
			//		var currentMatrix = Matrix.unit
			//		var currentVertex = SIMD3<Double>.zero
			//
			////		var triangles = [Triangle]()
			//		var vertexMode = VertexMode.triangle // should be changed before using
			////		var vertexBuffer = [SIMD3<Double>]()
			//		var vertexBuffer = [Int]()
			//
			//		var vertexList = [SIMD3<Double>]()
			//		var faceList = [[Int]]()
			//
			//		var frameNumber = 0
			//		func add(vertex: SIMD3<Double>) {
			//			let vertexIndex: Int // plus 1 because 1-indexed
			//			if let index = vertexList.firstIndex(of: vertex) {
			//				vertexIndex = index + 1
			//			} else {
			//				vertexList.append(vertex)
			//				vertexIndex = vertexList.count
			//			}
			//
			//			vertexBuffer.append(vertexIndex)
			//
			////			if currentMatrix != boneTable[10].matrix { return }
			//
			//			precondition(!vertexBuffer.isEmpty)
			//			switch vertexMode {
			//				case .triangle:
			//					guard vertexBuffer.count.isMultiple(of: 3) else { return }
			//					faceList.append([
			//						vertexBuffer[vertexBuffer.count - 3],
			//						vertexBuffer[vertexBuffer.count - 2],
			//						vertexBuffer[vertexBuffer.count - 1]
			//					])
			//				case .quadrilateral:
			//					guard vertexBuffer.count.isMultiple(of: 4) else { return }
			//					faceList.append([
			//						vertexBuffer[vertexBuffer.count - 4],
			//						vertexBuffer[vertexBuffer.count - 3],
			//						vertexBuffer[vertexBuffer.count - 1]
			//					])
			//					faceList.append([
			//						vertexBuffer[vertexBuffer.count - 3],
			//						vertexBuffer[vertexBuffer.count - 2],
			//						vertexBuffer[vertexBuffer.count - 1]
			//					])
			//				case .triangleStrip:
			//					guard vertexBuffer.count >= 3 else { return }
			//					if vertexBuffer.count.isMultiple(of: 2) {
			//						// even - reverse winding order
			//						faceList.append([
			//							vertexBuffer[vertexBuffer.count - 2],
			//							vertexBuffer[vertexBuffer.count - 3],
			//							vertexBuffer[vertexBuffer.count - 1]
			//						])
			//					} else {
			//						faceList.append([
			//							vertexBuffer[vertexBuffer.count - 3],
			//							vertexBuffer[vertexBuffer.count - 2],
			//							vertexBuffer[vertexBuffer.count - 1]
			//						])
			//					}
			//				case .quadrilateralStrip:
			//					guard vertexBuffer.count >= 4, vertexBuffer.count.isMultiple(of: 2) else { return }
			//					faceList.append([
			//						vertexBuffer[vertexBuffer.count - 4],
			//						vertexBuffer[vertexBuffer.count - 3],
			//						vertexBuffer[vertexBuffer.count - 2]
			//					])
			//					faceList.append([
			//						vertexBuffer[vertexBuffer.count - 3],
			//						vertexBuffer[vertexBuffer.count - 1],
			//						vertexBuffer[vertexBuffer.count - 2]
			//					])
			//			}
			//		}
			//
			//		reader: while true {
			//			let commands = try (0..<4).map { _ in try model.read(UInt8.self) }
			//
			//			guard let lastCommand = commands.filter({ $0 != 0 }).last else {
			//				fatalError("4 NOPs in a row")
			//			}
			//
			//			for command in commands {
			//				if command == 0xFF { break reader }
			//
			//				if [0x50, 0x51].contains(command) {
			//					print("UNKNOWN", "0x" + String(command, radix: 16))
			//					let argumentsLength = try model.read(UInt32.self)
			//					model.jump(bytes: argumentsLength)
			//					break
			//				}
			//
			//				if command == 0x52 {
			//					print("GPU command start")
			//					model.jump(bytes: 4)
			//					break
			//				}
			//
			//				if command == 0x53 { // UNKNOWN 0x53
			//					model.jump(bytes: 0x0c)
			//					print("UNKNOWN 0x53")
			//					// sometimes 0x53 has a 16-bit word after it (length of args?)
			//					break
			//				}
			//
			//				if command == 0x10 { // MTX_MODE
			//					let argument = try model.read(UInt32.self)
			//					let mode = switch argument {
			//							case 0: "Projection Matrix"
			//							case 1: "Position Matrix"
			//							case 2: "Position & Vector Simultaneous Set mode"
			//							case 3: "Texture Matrix"
			//							default: fatalError()
			//						}
			//
			//					print("MTX_MODE", mode)
			//				} else if command == 0x14 { // MTX_RESTORE
			//					let number = try model.read(UInt32.self)
			//					mtxRestores.append(number)
			//					currentMatrix = boneTable[Int(number) - 5].matrix
			//					print("MTX_RESTORE", number, boneTable[Int(number) - 5].name)
			//				} else if command == 0x1B { // MTX_SCALE
			//					let x = Double(try model.read(UInt32.self)) / 4096
			//					let y = Double(try model.read(UInt32.self)) / 4096
			//					let z = Double(try model.read(UInt32.self)) / 4096
			//
			//					print("MTX_SCALE", x, y, z)
			//				} else if command == 0x20 { // COLOR
			//					let color = try model.read(UInt32.self)
			//					let red = Double(color & 0b11111) / 0b11111
			//					let green = Double((color >> 5) & 0b11111) / 0b11111
			//					let blue = Double(color >> 10) / 0b11111
			//
			////					print("COLOR", red, green, blue)
			//				} else if command == 0x23 { // VTX_16
			//					let x = parse1_3_12(try model.read(UInt16.self))
			//					let y = parse1_3_12(try model.read(UInt16.self))
			//					let z = parse1_3_12(try model.read(UInt16.self))
			//					model.jump(bytes: 2)
			//
			//					currentVertex = SIMD3(x, y, z)
			//
			//					print("VTX_16", x, y, z, terminator: " ")
			//					print(format(currentVertex))
			//
			//					add(vertex: currentVertex.transformed(by: currentMatrix))
			//				} else if command == 0x25 { // VTX_XY
			//					let x = parse1_3_12(try model.read(UInt16.self))
			//					let y = parse1_3_12(try model.read(UInt16.self))
			//
			//					currentVertex.x = x
			//					currentVertex.y = y
			//					print("VTX_XY", x, y, terminator: " ")
			//					print(format(currentVertex))
			//
			//					add(vertex: currentVertex.transformed(by: currentMatrix))
			//				} else if command == 0x26 { // VTX_XZ
			//					let x = parse1_3_12(try model.read(UInt16.self))
			//					let z = parse1_3_12(try model.read(UInt16.self))
			//
			//					currentVertex.x = x
			//					currentVertex.z = z
			//					print("VTX_XZ", x, z, terminator: " ")
			//					print(format(currentVertex))
			//
			//					add(vertex: currentVertex.transformed(by: currentMatrix))
			//				} else if command == 0x27 { // VTX_YZ
			//					let y = parse1_3_12(try model.read(UInt16.self))
			//					let z = parse1_3_12(try model.read(UInt16.self))
			//
			//					currentVertex.y = y
			//					currentVertex.z = z
			//					print("VTX_YZ", y, z, terminator: " ")
			//					print(format(currentVertex))
			//
			//					add(vertex: currentVertex.transformed(by: currentMatrix))
			//				} else if command == 0x29 { // POLYGON_ATTR
			////					0-3   Light 0..3 Enable Flags (each bit: 0=Disable, 1=Enable)
			////					4-5   Polygon Mode  (0=Modulation,1=Decal,2=Toon/Highlight Shading,3=Shadow)
			////					6     Polygon Back Surface   (0=Hide, 1=Render)  ;Line-segments are always
			////					7     Polygon Front Surface  (0=Hide, 1=Render)  ;rendered (no front/back)
			////					11    Depth-value for Translucent Polygons  (0=Keep Old, 1=Set New Depth)
			////					12    Far-plane intersecting polygons       (0=Hide, 1=Render/clipped)
			////					13    1-Dot polygons behind DISP_1DOT_DEPTH (0=Hide, 1=Render)
			////					14    Depth Test, Draw Pixels with Depth    (0=Less, 1=Equal) (usually 0)
			////					15    Fog Enable                            (0=Disable, 1=Enable)
			////					16-20 Alpha      (0=Wire-Frame, 1..30=Translucent, 31=Solid)
			////					24-29 Polygon ID (00h..3Fh, used for translucent, shadow, and edge-marking)
			//					let attributes = try model.read(UInt32.self)
			//
			//					let backSurface = attributes & (1 << 6) > 0
			//					let frontSurface = attributes & (1 << 7) > 0
			//					let alpha = attributes >> 16 & 0b11111
			//					let poly = attributes >> 24 & 0b111111
			//
			//					print("POLYGON_ATTR", attributes, backSurface, frontSurface, alpha, poly)
			//				} else if command == 0x40 { // BEGIN_VTXS
			//					let argument = try model.read(UInt32.self)
			//					let mode = switch argument {
			//						case 0: "Separate Triangle(s)"
			//						case 1: "Separate Quadliteral(s)"
			//						case 2: "Triangle Strips"
			//						case 3: "Quadliteral Strips"
			//						default: fatalError()
			//					}
			//
			//					vertexMode = switch argument {
			//						case 0: .triangle
			//						case 1: .quadrilateral
			//						case 2: .triangleStrip
			//						case 3: .quadrilateralStrip
			//						default: fatalError()
			//					}
			//					vertexBuffer = []
			//
			//					print("BEGIN_VTXS", mode)
			//				} else if command == 0x41 { // END_VTXS
			//					vertexBuffer = []
			//					print("END_VTXS")
			//				} else {
			//					let argumentCount = argumentCountPerCommand[command]!
			//					let arguments = try model.read([UInt32].self, count: argumentCount)
			//					if ![0x22, 0x2A, 0x2B].contains(command) {
			//						print(commandNames[command]!, arguments)
			//					}
			//				}
			//			}
			//
			//			if argumentCountPerCommand[lastCommand] == 0 {
			//				model.jump(bytes: 4)
			//			}
			//		}
			//
			//		let vertexListText = vertexList
			//			.map { "v \($0.x) \($0.y) \($0.z)" }
			//			.joined(separator: "\n")
			//		let faceListText = faceList
			//			.map { "f " + $0.sorted().map(String.init).joined(separator: " ") }
			//			.joined(separator: "\n")
			//
			//		let filePath = URL(filePath: "/Users/simonomi/Desktop/cha01a_01.obj")
			//		try (vertexListText + "\n\n" + faceListText).write(to: filePath, atomically: false, encoding: .utf8)
			//
			//		let uniqueRestores = mtxRestores.uniqued().sorted()
			//		print("MTX_RESTOREs", String(repeating: ".", count: uniqueRestores.count))
			//		if uniqueRestores.count != numberOfBones, uniqueRestores.count != (numberOfBones - 1) {
			//			print(numberOfBones, uniqueRestores.count)
			//		}
        }
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
