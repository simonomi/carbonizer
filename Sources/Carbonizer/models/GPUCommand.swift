import BinaryParser

// TODO: clean this up SEVERLY
// make a packed/unpacked representation

enum InvalidGPUCommand: Error {
	case invalidCommand(UInt8)
	case invalidMatrixMode(UInt32)
	case invalidVertexMode(UInt32)
}

enum GPUCommandType: UInt8, Equatable {
	case noop = 0x00
	case matrixMode = 0x10
//	case matrixPush = 0x11
	case matrixPop = 0x12
//	case matrixStore = 0x13
	case matrixRestore = 0x14
	case matrixIdentity = 0x15
//	case matrixLoad4x4 = 0x16
	case matrixLoad4x3 = 0x17
//	case matrixMultiply4x4 = 0x18
//	case matrixMultiply4x3 = 0x19
//	case matrixMultiply3x3 = 0x1A
	case matrixScale = 0x1B
//	case matrixTranslate = 0x1C
	case color = 0x20
	case normal = 0x21
	case textureCoordinate = 0x22
	case vertex16 = 0x23
//	case vertex10 = 0x24
	case vertexXY = 0x25
	case vertexXZ = 0x26
	case vertexYZ = 0x27
//	case vertexDiff = 0x28
	case polygonAttributes = 0x29
	case textureImageParameter = 0x2A
	case texturePaletteBase = 0x2B
//	case materialColor0 = 0x30
//	case materialColor1 = 0x31
//	case lightVector = 0x32
//	case lightColor = 0x33
//	case shininess = 0x34
	case vertexBegin = 0x40
	case vertexEnd = 0x41
	
	case unknown50 = 0x50 // swap buffers ??
	case unknown51 = 0x51
	case commandsStart = 0x52
	case unknown53 = 0x53
	case commandsEnd = 0xFF // always followed by 0F 7F ?
	case commandsEnd1 = 0x0F
	case commandsEnd2 = 0x7F
	
	/// number of 32-bit arguments
	var argumentCount: Int? {
		switch self {
			case .noop, .matrixIdentity, .vertexEnd: 0
			case .matrixMode, .matrixPop, .matrixRestore, .color, .normal, .textureCoordinate, .vertexXY, .vertexXZ, .vertexYZ, .polygonAttributes, .textureImageParameter, .texturePaletteBase, .vertexBegin: 1
			case .vertex16: 2
			case .matrixScale: 3
			case .matrixLoad4x3: 12
			case .unknown50, .unknown51, .commandsStart, .unknown53, .commandsEnd, .commandsEnd1, .commandsEnd2: nil
		}
	}
}

extension GPUCommandType: BinaryConvertible {
	init(_ data: Datastream) throws {
		let raw = try data.read(UInt8.self)
		guard let possiblySelf = Self(rawValue: raw) else {
			throw InvalidGPUCommand.invalidCommand(raw)
		}
		self = possiblySelf
	}
	
	func write(to data: Datawriter) {
		data.write(rawValue)
	}
}

// TODO: check that all of these are accurate >.<
enum GPUCommand: Codable {
	case noop
	case matrixMode(MatrixMode)
	case matrixPop(Int8) // 1w - sign bit + u5
	case matrixRestore(UInt8) // 1w - u5
	case matrixIdentity
	case matrixLoad4x3([UInt32]) // 12w // Matrix4x3?
	case matrixScale(Double, Double, Double) // 3w, 2012
	case color(Color) // 1w - 555
	case normal(UInt32) // 1w
	case textureCoordinate(SIMD2<Double>) // 1w
	case vertex16(SIMD3<Double>) // 2w
	case vertexXY(x: Double, y: Double) // 1w
	case vertexXZ(x: Double, z: Double) // 1w
	case vertexYZ(y: Double, z: Double) // 1w
	case polygonAttributes(UInt32) // 1w
	case textureImageParameter(UInt32) // 1w
	case texturePaletteBase(UInt32) // 1w
	case vertexBegin(VertexMode)
	case vertexEnd
	
	case unknown50(UInt32, [UInt8])
	case unknown51(UInt32, [UInt8])
	case commandsStart(UInt32)
	case unknown53(UInt32, UInt32, UInt32) // 3w
	case commandsEnd // always followed by 0F 7F ?
	
	enum MatrixMode: Codable {
		case projection, position, positionAndVector, texture
		
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
	}
	
	enum VertexMode: Codable {
		case triangle, quadrilateral, triangleStrip, quadrilateralStrip
		
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
	}
}

extension GPUCommand.MatrixMode: BinaryConvertible {
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

extension GPUCommand.VertexMode: BinaryConvertible {
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

extension Datastream {
	fileprivate func readFixed412() throws -> Double {
		Double(try read(FixedPoint412.self))
	}
	
	fileprivate func readFixed124() throws -> Double {
		Double(try read(FixedPoint124.self))
	}
	
	fileprivate func readFixed2012() throws -> Double {
		Double(try read(FixedPoint2012.self))
	}
	
	fileprivate func readSigned6() throws -> Int8 {
		let raw = try read(UInt32.self)
		guard raw < (1 << 7) else {
			todo("throw")
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
			todo("throw")
		}
		
		return UInt8(raw)
	}
	
	func readCommands() throws -> [GPUCommand] {
		var commands: [GPUCommand] = []
		
	mainloop:
		while true {
			let rawCommandTypes = try (0..<4).map { _ in try read(UInt8.self) }
			
			for rawCommandType in rawCommandTypes {
				guard let commandType = GPUCommandType(rawValue: rawCommandType) else {
					throw InvalidGPUCommand.invalidCommand(rawCommandType)
				}
				
				let command: GPUCommand = switch commandType {
					case .noop: .noop
					case .matrixMode: .matrixMode(try read(GPUCommand.MatrixMode.self))
					case .matrixPop: .matrixPop(try readSigned6())
					case .matrixRestore: .matrixRestore(try readUnsigned5())
					case .matrixIdentity: .matrixIdentity
					case .matrixLoad4x3:
						.matrixLoad4x3(try read([UInt32].self, count: 12))
					case .matrixScale:
							.matrixScale(
								try readFixed2012(),
								try readFixed2012(),
								try readFixed2012()
							)
					case .color: .color(
						Color(try read(RGB555Color.self))
					)
					case .normal: .normal(try read(UInt32.self))
					case .textureCoordinate: .textureCoordinate(
						SIMD2(
							x: try readFixed124(),
							y: try readFixed124()
						)
					)
					case .vertex16: try {
						let command: GPUCommand = .vertex16(
							SIMD3(
								x: try readFixed412(),
								y: try readFixed412(),
								z: try readFixed412()
							)
						)
						jump(bytes: 2)
						return command
					}()
					case .vertexXY: .vertexXY(
						x: try readFixed412(),
						y: try readFixed412()
					)
					case .vertexXZ: .vertexXZ(
						x: try readFixed412(),
						z: try readFixed412()
					)
					case .vertexYZ: .vertexYZ(
						y: try readFixed412(),
						z: try readFixed412()
					)
					case .polygonAttributes: .polygonAttributes(try read(UInt32.self))
					case .textureImageParameter: .textureImageParameter(try read(UInt32.self))
					case .texturePaletteBase: .texturePaletteBase(try read(UInt32.self))
					case .vertexBegin: .vertexBegin(try read(GPUCommand.VertexMode.self))
					case .vertexEnd: .vertexEnd
					case .unknown50: try {
						let argumentLength = try read(UInt32.self)
						return .unknown50(argumentLength, try read([UInt8].self, count: argumentLength))
					}()
					case .unknown51: try {
						let argumentLength = try read(UInt32.self)
						return .unknown51(argumentLength, try read([UInt8].self, count: argumentLength))
					}()
					case .commandsStart: .commandsStart(try read(UInt32.self))
					case .unknown53:
							.unknown53(
								try read(UInt32.self),
								try read(UInt32.self),
								try read(UInt32.self)
							)
					case .commandsEnd, .commandsEnd1, .commandsEnd2: .commandsEnd
				}
				
//				print(command)
				
				commands.append(command)
				
				switch command {
					case .unknown50, .unknown51, .unknown53:
						continue mainloop // stop reading commands from this word
										  // and skip the argument count check
					case .commandsEnd:
						break mainloop
					default: ()
				}
				
				if case .commandsEnd = command {
					break mainloop
				}
			}
			
			guard let lastRawCommand = rawCommandTypes.filter({ $0 != 0 }).last,
				  let lastCommand = GPUCommandType(rawValue: lastRawCommand)
			else {
				todo("4 NOPs in a row; throw error")
			}
			
			if lastCommand.argumentCount == 0 {
				jump(bytes: 4)
			}
		}
		
		return commands
	}
}
