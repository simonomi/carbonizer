import BinaryParser

struct GPUCommands: Codable {
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
		case matrixLoad4x3([UInt32]) // 12w // Matrix4x3?
		// matrixMultiply4x4
		// matrixMultiply4x3
		// matrixMultiply3x3
		case matrixScale(Double, Double, Double) // 3w, 2012
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
		
		case unknown50(UInt32, [UInt8])
		case unknown51(UInt32, [UInt8])
		case commandsStart(UInt32) // this is the size of the commands
		case unknown53(UInt32, UInt32, UInt32) // 3w
		case commandsEnd // always followed by 0F 7F ?
						 // but after commandsStart's length
		
		enum MatrixMode: String, Codable {
			case projection, position, positionAndVector, texture
		}
		
		enum VertexMode: String, Codable {
			case triangle, quadrilateral, triangleStrip, quadrilateralStrip
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
	init(_ data: Datastream) throws {
		commands = []
		
	mainloop:
		while true {
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
							.matrixLoad4x3(try data.read([UInt32].self, count: 12))
					case .matrixScale:
							.matrixScale(
								Double(try data.read(FixedPoint2012.self)),
								Double(try data.read(FixedPoint2012.self)),
								Double(try data.read(FixedPoint2012.self))
							)
					case .color: try {
						let color: Command = .color(
							Color(try data.read(RGB555Color.self))
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
					case .unknown50: try {
						let argumentLength = try data.read(UInt32.self)
						return .unknown50(argumentLength, try data.read([UInt8].self, count: argumentLength))
					}()
					case .unknown51: try {
						let argumentLength = try data.read(UInt32.self)
						return .unknown51(argumentLength, try data.read([UInt8].self, count: argumentLength))
					}()
					case .commandsStart:
							.commandsStart(try data.read(UInt32.self))
					case .unknown53:
							.unknown53(
								try data.read(UInt32.self),
								try data.read(UInt32.self),
								try data.read(UInt32.self)
							)
					case .commandsEnd, .commandsEnd1, .commandsEnd2: .commandsEnd
					default: throw InvalidGPUCommand.unsupportedCommand(commandType)
				}
				
//				print(command)
				
				commands.append(command)
				
				switch command {
					case .unknown50, .unknown51, .commandsStart, .unknown53:
						continue mainloop // stop reading commands from this word
										  // and skip the argument count check
					case .commandsEnd:
						return
					default: ()
				}
			}
			
			guard let lastRawCommand = rawCommandTypes.filter({ $0 != 0 }).last,
				  let lastCommand = GPUCommandType(rawValue: lastRawCommand)
			else {
				throw InvalidGPUCommand.fourNOPs
			}
			
			// TODO: why
			if lastCommand.argumentCount == 0 {
				data.jump(bytes: 4)
			}
		}
	}
	
	func write(to data: Datawriter) {
		todo()
	}
}

extension Datastream {
	fileprivate func readSigned6() throws -> Int8 {
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
	
	fileprivate func readUnsigned5() throws -> UInt8 {
		let raw = try read(UInt32.self)
		guard raw < (1 << 6) else {
			throw InvalidGPUCommand.invalidUnsigned5(raw: raw)
		}
		
		return UInt8(raw)
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
	
	init(_ data: Datastream) throws {
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
	
	init(_ data: Datastream) throws {
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
