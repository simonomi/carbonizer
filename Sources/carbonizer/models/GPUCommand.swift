import BinaryParser

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

enum GPUCommand {
	case noop
	case matrixMode(MatrixMode)
	case matrixPop(UInt32) // 1w - i6
	case matrixRestore(UInt32) // 1w - u5
	case matrixIdentity
	case matrixLoad4x3([UInt32]) // 12w
	case matrixScale(UInt32, UInt32, UInt32) // 3w - signed 20.12
	case color(UInt32) // 1w - 555
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
	
	enum MatrixMode: UInt32 {
		case projection, position, positionAndVector, texture
	}
	
	enum VertexMode: UInt32 {
		case triangle, quadrilateral, triangleStrip, quadrilateralStrip
	}
}

extension GPUCommand.MatrixMode: BinaryConvertible {
	init(_ data: Datastream) throws {
		let raw = try data.read(UInt32.self)
		guard let possiblySelf = Self(rawValue: raw) else {
			throw InvalidGPUCommand.invalidMatrixMode(raw)
		}
		self = possiblySelf
	}
	
	func write(to data: Datawriter) {
		data.write(rawValue)
	}
}

extension GPUCommand.VertexMode: BinaryConvertible {
	init(_ data: Datastream) throws {
		let raw = try data.read(UInt32.self)
		guard let possiblySelf = Self(rawValue: raw) else {
			throw InvalidGPUCommand.invalidVertexMode(raw)
		}
		self = possiblySelf
	}
	
	func write(to data: Datawriter) {
		data.write(rawValue)
	}
}

extension Datastream {
	fileprivate func readFixed412() throws -> Double {
		Double(try read(Int16.self)) / Double(1 << 12)
	}
	
	fileprivate func readFixed124() throws -> Double {
		Double(try read(Int16.self)) / Double(1 << 4)
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
					case .matrixPop: .matrixPop(try read(UInt32.self))
					case .matrixRestore: .matrixRestore(try read(UInt32.self))
					case .matrixIdentity: .matrixIdentity
					case .matrixLoad4x3:
						.matrixLoad4x3(try read([UInt32].self, count: 12))
					case .matrixScale:
							.matrixScale(
								try read(UInt32.self),
								try read(UInt32.self),
								try read(UInt32.self)
							)
					case .color: .color(try read(UInt32.self))
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
				// TODO: throw error
				fatalError("4 NOPs in a row")
			}
			
			if lastCommand.argumentCount == 0 {
				jump(bytes: 4)
			}
		}
		
		return commands
	}
}
