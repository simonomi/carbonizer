import BinaryParser

struct MeshCommands {
	var commands: [Command]
	
	enum Command: Codable {
		case unknown50([UInt8])
		case unknown51([UInt8])
		case unknown52([GPUCommands.Command])
		case unknown53(UInt16, UInt32, UInt32, UInt32)
		case end // 0xFF_0F_7F_00
	}
}

extension MeshCommands: BinaryConvertible {
	enum ReadError: Error, CustomStringConvertible {
		case invalidCommand(id: UInt16)
		case unexpectedArgument(commandID: UInt16, argument: UInt16)
		
		var description: String {
			switch self {
				case .invalidCommand(id: let id):
					"invalid mesh command: \(.red)\(hex(Int(id)))\(.normal)"
				case .unexpectedArgument(let commandID, let argument):
					"unexpected argument for command \(commandID): \(argument)"
			}
		}
	}
	
	init(_ data: inout Datastream) throws {
		commands = []
		
	mainloop:
		while true {
			let commandID = try data.read(UInt16.self)
			let unknownArgument = try data.read(UInt16.self)
			
			switch commandID {
				case 0x50:
					guard unknownArgument == 0 else {
						throw ReadError.unexpectedArgument(commandID: commandID, argument: unknownArgument)
					}
					
					let argumentLength = try data.read(UInt32.self)
					commands.append(.unknown50(try data.read([UInt8].self, count: argumentLength)))
				case 0x51:
					guard unknownArgument == 0 else {
						throw ReadError.unexpectedArgument(commandID: commandID, argument: unknownArgument)
					}
					
					let argumentLength = try data.read(UInt32.self)
					commands.append(.unknown51(try data.read([UInt8].self, count: argumentLength)))
				case 0x52:
					guard unknownArgument == 0 else {
						throw ReadError.unexpectedArgument(commandID: commandID, argument: unknownArgument)
					}
					
					let argumentLength = try data.read(UInt32.self)
					var gpuCommandData = Datastream(try data.read([UInt8].self, count: argumentLength))
					
					commands.append(.unknown52(try gpuCommandData.read(GPUCommands.self).commands))
				case 0x53:
					commands.append(
						.unknown53(
							unknownArgument,
							try data.read(UInt32.self),
							try data.read(UInt32.self),
							try data.read(UInt32.self)
						)
					)
				case 0x0F_FF:
					guard unknownArgument == 0x7F else {
						throw ReadError.unexpectedArgument(commandID: commandID, argument: unknownArgument)
					}
					
					commands.append(.end)
					
					break mainloop
				default:
					throw ReadError.invalidCommand(id: commandID)
			}
		}
	}
	
	func write(to data: Datawriter) {
		for command in commands {
			switch command {
				case .unknown50(let bytes):
					data.write(UInt32(0x50))
					data.write(UInt32(bytes.count))
					data.write(bytes)
				case .unknown51(let bytes):
					data.write(UInt32(0x51))
					data.write(UInt32(bytes.count))
					data.write(bytes)
				case .unknown52(let gpuCommands):
					data.write(UInt32(0x52))
					
					let gpuCommandsBuffer = Datawriter()
					gpuCommandsBuffer.write(GPUCommands(commands: gpuCommands))
					
					data.write(UInt32(gpuCommandsBuffer.bytes.count))
					data.write(gpuCommandsBuffer.bytes)
				case .unknown53(let argument, let firstWord, let secondWord, let thirdWord):
					data.write(UInt16(0x53))
					data.write(argument)
					data.write(UInt32(firstWord))
					data.write(UInt32(secondWord))
					data.write(UInt32(thirdWord))
				case .end:
					data.write(UInt32(0x7F_0F_FF))
			}
		}
	}
}
