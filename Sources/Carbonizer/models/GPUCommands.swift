import BinaryParser

struct GPUCommands {
	var commands: [Command]
	
	enum Command: Codable {
		case noop
		case matrixMode(MatrixMode)
		// matrixPush
		case matrixPop(Int8) // 1w - sign bit + u5
		// matrixStore
		case matrixRestore(UInt8) // 1w - u5
		case matrixIdentity
		// matrixLoad4x4
		case matrixLoad4x3([Double]) // 12w // Matrix4x3?
		// matrixMultiply4x4
		// matrixMultiply4x3
		// matrixMultiply3x3
		case matrixScale(x: Double, y: Double, z: Double) // 3w, 2012
														  // matrixTranslate
		case color(Color) // 1w - 555
		case normal(UInt32) // 1w
		case textureCoordinate(SIMD2<Double>) // 1w
		case vertex16(SIMD3<Double>) // 2w
		// vertex10
		case vertexXY(x: Double, y: Double) // 1w
		case vertexXZ(x: Double, z: Double) // 1w
		case vertexYZ(y: Double, z: Double) // 1w
		// vertexDiff
		case polygonAttributes(UInt32) // 1w
		case textureImageParameter(UInt32) // 1w
		case texturePaletteBase(UInt32) // 1w
		// materialColor0
		// materialColor1
		// lightVector
		// lightColor
		// shininess
		case vertexBegin(VertexMode)
		case vertexEnd
		
		// swapBuffers
		// setViewport
		// testBox
		// testPosition
		// testVector
		
		enum MatrixMode: String, Codable {
			case projection, position, positionAndVector, texture
		}
		
		enum VertexMode: String, Codable {
			case triangle, quadrilateral, triangleStrip, quadrilateralStrip
		}
		
		var type: GPUCommandType {
			switch self {
				case .noop: .noop
				case .matrixMode: .matrixMode
				case .matrixPop: .matrixPop
				case .matrixRestore: .matrixRestore
				case .matrixIdentity: .matrixIdentity
				case .matrixLoad4x3: .matrixLoad4x3
				case .matrixScale: .matrixScale
				case .color: .color
				case .normal: .normal
				case .textureCoordinate: .textureCoordinate
				case .vertex16: .vertex16
				case .vertexXY: .vertexXY
				case .vertexXZ: .vertexXZ
				case .vertexYZ: .vertexYZ
				case .polygonAttributes: .polygonAttributes
				case .textureImageParameter: .textureImageParameter
				case .texturePaletteBase: .texturePaletteBase
				case .vertexBegin: .vertexBegin
				case .vertexEnd: .vertexEnd
			}
		}
	}
}

enum InvalidGPUCommand: Error {
	case invalidCommand(UInt8)
	case unsupportedCommand(GPUCommandType)
	case invalidMatrixMode(UInt32)
	case invalidVertexMode(UInt32)
	case invalidSigned6(raw: UInt32)
	case invalidUnsigned5(raw: UInt32)
	case fourNOPs
	
	// TODO: CustomStringConvertible
}

extension GPUCommands: BinaryConvertible {
	init(_ data: inout Datastream) throws {
		commands = []
		
		while data.offset < data.bytes.endIndex {
			let rawCommandTypes = try (0..<4).map { _ in try data.read(UInt8.self) }
			
			for rawCommandType in rawCommandTypes {
				guard let commandType = GPUCommandType(rawValue: rawCommandType) else {
					throw InvalidGPUCommand.invalidCommand(rawCommandType)
				}
				
				let command: Command = switch commandType {
					case .noop: .noop
					case .matrixMode:
							.matrixMode(try data.read(Command.MatrixMode.self))
					case .matrixPop:
							.matrixPop(try data.readSigned6())
					case .matrixRestore:
							.matrixRestore(try data.readUnsigned5())
					case .matrixIdentity:
							.matrixIdentity
					case .matrixLoad4x3:
							.matrixLoad4x3(
								try data.read([FixedPoint2012].self, count: 12)
									.map(Double.init)
							)
					case .matrixScale:
							.matrixScale(
								x: Double(try data.read(FixedPoint2012.self)),
								y: Double(try data.read(FixedPoint2012.self)),
								z: Double(try data.read(FixedPoint2012.self))
							)
					case .color: try {
						let color: Command = .color(
							Color(try data.read(Color555.self))
						)
						data.jump(bytes: 2)
						return color
					}()
					case .normal: .normal(try data.read(UInt32.self))
					case .textureCoordinate: .textureCoordinate(
						SIMD2(
							x: Double(try data.read(FixedPoint124.self)),
							y: Double(try data.read(FixedPoint124.self))
						)
					)
					case .vertex16: try {
						let command: Command = .vertex16(
							SIMD3(
								x: Double(try data.read(FixedPoint412.self)),
								y: Double(try data.read(FixedPoint412.self)),
								z: Double(try data.read(FixedPoint412.self))
							)
						)
						data.jump(bytes: 2)
						return command
					}()
					case .vertexXY: .vertexXY(
						x: Double(try data.read(FixedPoint412.self)),
						y: Double(try data.read(FixedPoint412.self))
					)
					case .vertexXZ: .vertexXZ(
						x: Double(try data.read(FixedPoint412.self)),
						z: Double(try data.read(FixedPoint412.self))
					)
					case .vertexYZ: .vertexYZ(
						y: Double(try data.read(FixedPoint412.self)),
						z: Double(try data.read(FixedPoint412.self))
					)
					case .polygonAttributes:
							.polygonAttributes(try data.read(UInt32.self))
					case .textureImageParameter:
							.textureImageParameter(try data.read(UInt32.self))
					case .texturePaletteBase:
							.texturePaletteBase(try data.read(UInt32.self))
					case .vertexBegin:
							.vertexBegin(try data.read(Command.VertexMode.self))
					case .vertexEnd: .vertexEnd
					default: throw InvalidGPUCommand.unsupportedCommand(commandType)
				}
				
//				print(command)
				
				commands.append(command)
			}
			
			guard let lastRawCommand = rawCommandTypes.filter({ $0 != 0 }).last,
				  let lastCommand = GPUCommandType(rawValue: lastRawCommand)
			else {
				throw InvalidGPUCommand.fourNOPs
			}
			
			// see page 172 (aka 190)
			if lastCommand.argumentCount == 0 {
				data.jump(bytes: 4)
			}
		}
	}
	
	func write(to data: Datawriter) {
		for commandQuartet in commands.chunked(maxSize: 4) {
			let commandTypes = commandQuartet.map(\.type)
			
			for type in commandTypes {
				data.write(type)
			}
			
			for command in commandQuartet {
				switch command {
					case .noop, .matrixIdentity, .vertexEnd: ()
					case .matrixMode(let mode):
						data.write(mode)
					case .matrixPop(let signed6):
						data.writeSigned6(signed6)
					case .matrixRestore(let unsigned5):
						data.writeUnsigned5(unsigned5)
					case .matrixLoad4x3(let transforms):
						data.write(transforms.map { FixedPoint2012($0) })
					case .matrixScale(x: let x, y: let y, z: let z):
						data.write(FixedPoint2012(x))
						data.write(FixedPoint2012(y))
						data.write(FixedPoint2012(z))
					case .color(let color):
						data.write(Color555(color))
						data.jump(bytes: 2)
					case .normal(let normal):
						data.write(normal)
					case .textureCoordinate(let point):
						data.write(FixedPoint124(point.x))
						data.write(FixedPoint124(point.y))
					case .vertex16(let vertex):
						data.write(FixedPoint412(vertex.x))
						data.write(FixedPoint412(vertex.y))
						data.write(FixedPoint412(vertex.z))
						data.jump(bytes: 2)
					case .vertexXY(x: let x, y: let y):
						data.write(FixedPoint412(x))
						data.write(FixedPoint412(y))
					case .vertexXZ(x: let x, z: let z):
						data.write(FixedPoint412(x))
						data.write(FixedPoint412(z))
					case .vertexYZ(y: let y, z: let z):
						data.write(FixedPoint412(y))
						data.write(FixedPoint412(z))
					case .polygonAttributes(let value):
						data.write(value)
					case .textureImageParameter(let value):
						data.write(value)
					case .texturePaletteBase(let value):
						data.write(value)
					case .vertexBegin(let vertexMode):
						data.write(vertexMode)
				}
			}
			
			// see page 172 (aka 190)
			if let lastCommand = commandTypes.last(where: { $0 != .noop }),
			   lastCommand.argumentCount == 0 {
				data.jump(bytes: 4)
			}
		}
		
		data.fourByteAlign()
	}
}

extension Datastream {
	fileprivate mutating func readSigned6() throws -> Int8 {
		let raw = try read(UInt32.self)
		guard raw < (1 << 7) else {
			throw InvalidGPUCommand.invalidSigned6(raw: raw)
		}
		
		let sign = (raw >> 5) > 0
		let integer = Int8(raw & 0b11111)
		
		return if sign {
			-integer
		} else {
			integer
		}
	}
	
	fileprivate mutating func readUnsigned5() throws -> UInt8 {
		let raw = try read(UInt32.self)
		guard raw < (1 << 6) else {
			throw InvalidGPUCommand.invalidUnsigned5(raw: raw)
		}
		
		return UInt8(raw)
	}
}

extension Datawriter {
	fileprivate func writeSigned6(_ signed6: Int8) {
		if signed6 >= 0 {
			write(signed6)
		} else {
			write((1 << 5) | signed6.magnitude)
		}
	}
	
	fileprivate func writeUnsigned5(_ unsigned5: UInt8) {
		write(UInt32(unsigned5))
	}
}

extension GPUCommands.Command.MatrixMode: BinaryConvertible {
	init?(raw: UInt32) {
		switch raw {
			case 0: self = .projection
			case 1: self = .position
			case 2: self = .positionAndVector
			case 3: self = .texture
			default: return nil
		}
	}
	
	var raw: UInt32 {
		switch self {
			case .projection: 0
			case .position: 1
			case .positionAndVector: 2
			case .texture: 3
		}
	}
	
	init(_ data: inout Datastream) throws {
		let raw = try data.read(UInt32.self)
		guard let possiblySelf = Self(raw: raw) else {
			throw InvalidGPUCommand.invalidMatrixMode(raw)
		}
		self = possiblySelf
	}
	
	func write(to data: Datawriter) {
		data.write(raw)
	}
}

extension GPUCommands.Command.VertexMode: BinaryConvertible {
	init?(raw: UInt32) {
		switch raw {
			case 0: self = .triangle
			case 1: self = .quadrilateral
			case 2: self = .triangleStrip
			case 3: self = .quadrilateralStrip
			default: return nil
		}
	}
	
	var raw: UInt32 {
		switch self {
			case .triangle: 0
			case .quadrilateral: 1
			case .triangleStrip: 2
			case .quadrilateralStrip: 3
		}
	}
	
	init(_ data: inout Datastream) throws {
		let raw = try data.read(UInt32.self)
		guard let possiblySelf = Self(raw: raw) else {
			throw InvalidGPUCommand.invalidVertexMode(raw)
		}
		self = possiblySelf
	}
	
	func write(to data: Datawriter) {
		data.write(raw)
	}
}
