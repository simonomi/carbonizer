import BinaryParser
import Foundation

struct DEX {
	var commands: [[Command]]
	
	enum Command {
		case dialogue(Dialogue)
		case spawn(Character, Int32, x: Int32, y: Int32, Int32)
		case despawn(Character)
		case fadeOut(frameCount: Int32)
		case fadeIn(frameCount: Int32)
		case unownedDialogue(Dialogue)
		case turnTo(Character, angle: Int32)
		case turn1To(Character, angle: Int32, frameCount: Int32, Int32)
		case turnTowards(Character, target: Character, frameCount: Int32, Int32)
		case turn2To(Character, angle: Int32, frameCount: Int32, Int32)
		case turnTowards2(Character, target: Character, Int32, frameCount: Int32, Int32)
		case moveTo(Character, x: Int32, y: Int32, frameCount: Int32, Int32)
		case moveBy(Character, relativeX: Int32, relativeY: Int32, frameCount: Int32, Int32)
		case delay(frameCount: Int32)
		case clean1(Int32, Fossil)
		case clean2(Int32, Fossil)
		case angleCamera(fov: Int32, xRotation: Int32, yRotation: Int32, targetDistance: Int32, frameCount: Int32, Int32)
		case startMusic(id: Int32)
		case fadeMusic(frameCount: Int32)
		case playSound(id: Int32)
		case characterEffect(Character, Effect)
		case clearEffects(Character)
		case characterMovement(Character, Movement)
		case dialogueChoice(Dialogue, Int32, choices: Dialogue)
		case imageFadeOut(frameCount: Int32, Int32)
		case imageSlideIn(Image, Int32, frameCount: Int32, Int32)
		case imageFadeIn(Image, Int32, frameCount: Int32, Int32)
		case revive(Vivosaur)
		case startTurning(Character, target: Character)
		case stopTurning(Character)
		
		case unknown(type: UInt32, arguments: [Int32])
		
		struct Dialogue: Codable {
			var id: Int32
			init(_ id: Int32) { self.id = id }
		}
		
		struct Character: Codable {
			var id: Int32
			init(_ id: Int32) { self.id = id }
		}
		
		struct Fossil: Codable {
			var id: Int32
			init(_ id: Int32) { self.id = id }
		}
		
		enum Effect: Codable {
			case haha
			case threeWhiteLines
			case threeRedLines
			case questionMark
			case thinking
			case ellipses
			case lightBulb
			case unknown(Int32)
		}
		
		enum Movement: Codable {
			case jump
			case quake
			case unknown(Int32)
		}
		
		struct Image: Codable {
			var id: Int32
			init(_ id: Int32) { self.id = id }
		}
		
		struct Vivosaur: Codable {
			var id: Int32
			init(_ id: Int32) { self.id = id }
		}
		
		enum InvalidCommand: Error {
			case invalidCommand(command: String, fullCommand: Substring)
			case invalidNumberOfArguments(expected: Int, got: Int, command: Substring)
			case invalidArgument(argument: Substring, command: Substring)
		}
	}
	
	@BinaryConvertible
	struct Binary {
		var magicBytes = "DEX"
		var numberOfScenes: UInt32
		var sceneOffsetsStart: UInt32 = 0xC
		@Count(givenBy: \Self.numberOfScenes)
		@Offset(givenBy: \Self.sceneOffsetsStart)
		var sceneOffsets: [UInt32]
		@Offsets(givenBy: \Self.sceneOffsets)
		var script: [Scene]
		
		@BinaryConvertible
		struct Scene {
			var numberOfCommands: UInt32
			var offsetsOffset: UInt32 = 0x8
			@Count(givenBy: \Self.numberOfCommands)
			@Offset(givenBy: \Self.offsetsOffset)
			var commandOffsets: [UInt32]
			@Offsets(givenBy: \Self.commandOffsets)
			var commands: [Command]
			
			@BinaryConvertible
			struct Command {
				var type: UInt32
				var numberOfArguments: UInt32
				var argumentsStart: UInt32 = 0xC
				@Count(givenBy: \Self.numberOfArguments)
				@Offset(givenBy: \Self.argumentsStart)
				var arguments: [Int32]
			}
		}
	}
}

// MARK: packed
extension DEX: FileData {
	static let fileExtension = "dex.txt"
	
	init(_ binary: Binary) {
		commands = binary.script
			.map(\.commands)
			.recursiveMap(Command.init)
	}
}

extension DEX.Command {
	init(_ commandBinary: DEX.Binary.Scene.Command) {
		let args = commandBinary.arguments
		self = switch commandBinary.type {
			case 1:  .dialogue(Dialogue(args[0]))
			case 7:  .spawn(Character(args[0]), args[1], x: args[2], y: args[3], args[4])
			case 14: .despawn(Character(args[0]))
			case 20: .fadeOut(frameCount: args[0])
			case 21: .fadeIn(frameCount: args[0])
			case 32: .unownedDialogue(Dialogue(args[0]))
			case 34: .turnTo(Character(args[0]), angle: args[1])
			case 35: .turn1To(Character(args[0]), angle: args[1], frameCount: args[2], args[3])
			case 36: .turnTowards(Character(args[0]), target: Character(args[1]), frameCount: args[2], args[3])
			case 37: .turn2To(Character(args[0]), angle: args[1], frameCount: args[2], args[3])
			case 38: .turnTowards2(Character(args[0]), target: Character(args[1]), args[2], frameCount: args[3], args[4])
			case 43: .moveTo(Character(args[0]), x: args[1], y: args[2], frameCount: args[3], args[4])
			case 45: .moveBy(Character(args[0]), relativeX: args[1], relativeY: args[2], frameCount: args[3], args[4])
			case 56: .delay(frameCount: args[0])
			case 58: .clean1(args[0], Fossil(args[1]))
			case 59: .clean2(args[0], Fossil(args[1]))
			case 61: .angleCamera(fov: args[0], xRotation: args[1], yRotation: args[2], targetDistance: args[3], frameCount: args[4], args[5])
			case 117: .startMusic(id: args[0])
			case 124: .fadeMusic(frameCount: args[0])
			case 125: .playSound(id: args[0])
			case 129: .characterEffect(Character(args[0]), Effect(args[1]))
			case 131: .clearEffects(Character(args[0]))
			case 135: .characterMovement(Character(args[0]), Movement(args[1]))
			case 144: .dialogueChoice(Dialogue(args[0]), args[1], choices: Dialogue(args[2]))
			case 154: .imageFadeOut(frameCount: args[0], args[1])
			case 155: .imageSlideIn(Image(args[0]), args[1], frameCount: args[2], args[3])
			case 157: .imageFadeIn(Image(args[0]), args[1], frameCount: args[2], args[3])
			case 191: .revive(Vivosaur(args[0]))
			case 200: .startTurning(Character(args[0]), target: Character(args[1]))
			case 201: .stopTurning(Character(args[0]))
			default:  .unknown(type: commandBinary.type, arguments: args)
		}
	}
	
	var typeAndArguments: (UInt32, [Int32]) {
		switch self {
			case .dialogue(let dialogue): 
				(1, [dialogue.id])
			case .spawn(let character, let unknown1, x: let x, y: let y, let unknown2):
				(7, [character.id, unknown1, x, y, unknown2])
			case .despawn(let character):
				(14, [character.id])
			case .fadeOut(let frameCount):
				(20, [frameCount])
			case .fadeIn(let frameCount):
				(21, [frameCount])
			case .unownedDialogue(let dialogue):
				(32, [dialogue.id])
			case .turnTo(let character, let angle):
				(34, [character.id, angle])
			case .turn1To(let character, let angle, let frameCount, let unknown):
				(35, [character.id, angle, frameCount, unknown])
			case .turnTowards(let character, let target, let frameCount, let unknown):
				(36, [character.id, target.id, frameCount, unknown])
			case .turn2To(let character, let angle, let frameCount, let unknown):
				(37, [character.id, angle, frameCount, unknown])
			case .turnTowards2(let character, let target, let unknown1, let frameCount, let unknown2):
				(38, [character.id, target.id, unknown1, frameCount, unknown2])
			case .moveTo(let character, let x, let y, let frameCount, let unknown):
				(43, [character.id, x, y, frameCount, unknown])
			case .moveBy(let character, let relativeX, let relativeY, let frameCount, let unknown):
				(45, [character.id, relativeX, relativeY, frameCount, unknown])
			case .delay(let framecount):
				(56, [framecount])
			case .clean1(let int32, let fossil):
				(58, [int32, fossil.id])
			case .clean2(let int32, let fossil):
				(59, [int32, fossil.id])
			case .angleCamera(let fov, let xRotation, let yRotation, let targetDistance, let frameCount, let unknown):
				(61, [fov, xRotation, yRotation, targetDistance, frameCount, unknown])
			case .startMusic(let id):
				(117, [id])
			case .fadeMusic(let framecount):
				(124, [framecount])
			case .playSound(let id):
				(125, [id])
			case .characterEffect(let character, let effect):
				(129, [character.id, effect.id])
			case .clearEffects(let character):
				(131, [character.id])
			case .characterMovement(let character, let movement):
				(135, [character.id, movement.id])
			case .dialogueChoice(let dialogue, let unknown, let choices):
				(144, [dialogue.id, unknown, choices.id])
			case .imageFadeOut(let framecount, let unknown):
				(154, [framecount, unknown])
			case .imageSlideIn(let image, let unknown1, let frameCount, let unknown2):
				(155, [image.id, unknown1, frameCount, unknown2])
			case .imageFadeIn(let image, let unknown1, let frameCount, let unknown2):
				(157, [image.id, unknown1, frameCount, unknown2])
			case .revive(let vivosaur):
				(191, [vivosaur.id])
			case .startTurning(let character, let target):
				(200, [character.id, target.id])
			case .stopTurning(let character):
				(201, [character.id])
			case .unknown(let type, let arguments):
				(type, arguments)
		}
	}
}

extension DEX.Command.Effect {
	init(_ type: Int32) {
		self = switch type {
			case 4:  .haha
			case 5:  .threeWhiteLines
			case 7:  .threeRedLines
			case 8:  .questionMark
			case 9:  .thinking
			case 22: .ellipses
			case 23: .lightBulb
			default: .unknown(type)
		}
	}
	
	var id: Int32 {
		switch self {
			case .haha: 4
			case .threeWhiteLines: 5
			case .threeRedLines: 7
			case .questionMark: 8
			case .thinking: 9
			case .ellipses: 22
			case .lightBulb: 23
			case .unknown(let type): type
		}
	}
}

extension DEX.Command.Movement {
	init(_ type: Int32) {
		self = switch type {
			case 1:  .jump
			case 8:  .quake
			default: .unknown(type)
		}
	}
	
	var id: Int32 {
		switch self {
			case .jump: 1
			case .quake: 8
			case .unknown(let type): type
		}
	}
}

extension DEX.Binary: FileData {
    static let fileExtension = ""
    
	init(_ dex: DEX) {
		numberOfScenes = UInt32(dex.commands.count)
		
		script = dex.commands.map(Scene.init)
		
		sceneOffsets = createOffsets(
			start: sceneOffsetsStart + numberOfScenes * 4,
			sizes: script.map { $0.size() }
		)
	}
}

// MARK: unpacked
extension DEX: BinaryConvertible {
	enum DEXError: Error {
		case invalidUTF8
	}
	
    
    init(_ data: Datastream) throws {
        let string = try data.read(String.self) // TODO: null termination?
        
        commands = try string
            .split(separator: "\n\n")
            .map {
                try $0.split(separator: "\n")
                    .map(DEX.Command.init)
            }
    }
    
    func write(to data: Datawriter) {
        let string = commands
            .recursiveMap(String.init)
            .map { $0.joined(separator: "\n") }
            .joined(separator: "\n\n")
        
        data.write(string) // TODO: null termination?
    }
    
//	init(unpacked bytes: Data) throws {
//		guard let string = String(bytes: bytes, encoding: .utf8) else {
//			throw DEXError.invalidUTF8
//		}
//		try self.init(unpacked: string)
//	}
//	
//	init(unpacked: String) throws {
//		commands = try unpacked
//			.split(separator: "\n\n")
//			.map {
//				try $0.split(separator: "\n")
//					.map(DEX.Command.init)
//			}
//	}
//	
//	func toUnpacked() throws -> String {
//		try commands
//			.map {
//				try $0.map(String.init)
//					.joined(separator: "\n")
//			}
//			.joined(separator: "\n\n")
//	}
}

extension DEX.Command {
	init(_ text: Substring) throws {
		let (command, arguments) = parse(command: text)
		
		switch command {
			case "dialogue":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let dialogue = Dialogue(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .dialogue(dialogue)
			case "spawn at , unknowns:":
				guard arguments.count == 4 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 4, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let (x, y) = position(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let unknown1 = Int32(arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let unknown2 = Int32(arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				self = .spawn(character, unknown1, x: x, y: y, unknown2)
			case "despawn":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .despawn(character)
			case "fade out":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let frameCount = frames(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .fadeOut(frameCount: frameCount)
			case "fade in":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let frameCount = frames(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .fadeIn(frameCount: frameCount)
			case "unowned dialogue":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let dialogue = Dialogue(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .unownedDialogue(dialogue)
			case "turn to":
				guard arguments.count == 2 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 2, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let angle = degrees(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				self = .turnTo(character, angle: angle)
			case "turn1 to over , unknown:":
				guard arguments.count == 4 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 4, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let angle = degrees(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let frameCount = frames(from: arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let unknown = Int32(arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				self = .turn1To(character, angle: angle, frameCount: frameCount, unknown)
			case "turn towards over , unknown:":
				guard arguments.count == 4 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 4, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let target = Character(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let frameCount = frames(from: arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let unknown = Int32(arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				self = .turnTowards(character, target: target, frameCount: frameCount, unknown)
			case "turn2 to over , unknown:":
				guard arguments.count == 4 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 4, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let angle = degrees(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let frameCount = frames(from: arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let unknown = Int32(arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				self = .turn2To(character, angle: angle, frameCount: frameCount, unknown)
			case "turn towards over , unknowns:":
				guard arguments.count == 5 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 5, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let target = Character(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let frameCount = frames(from: arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let unknown1 = Int32(arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				guard let unknown2 = Int32(arguments[4]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[4], command: text)
				}
				self = .turnTowards2(character, target: target, unknown1, frameCount: frameCount, unknown2)
			case "move to over , unknown:":
				guard arguments.count == 4 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 4, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let (x, y) = position(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let frameCount = frames(from: arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let unknown = Int32(arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				self = .moveTo(character, x: x, y: y, frameCount: frameCount, unknown)
			case "move by over , unknown:":
				guard arguments.count == 4 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 4, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let (x, y) = position(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let frameCount = frames(from: arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let unknown = Int32(arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				self = .moveBy(character, relativeX: x, relativeY: y, frameCount: frameCount, unknown)
			case "delay":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let frameCount = frames(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .delay(frameCount: frameCount)
			case "clean1 , unknown:":
				guard arguments.count == 2 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 2, got: arguments.count, command: text)
				}
				guard let fossil = Fossil(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let unknown = Int32(arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				self = .clean1(unknown, fossil)
			case "clean2 , unknown:":
				guard arguments.count == 2 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 2, got: arguments.count, command: text)
				}
				guard let fossil = Fossil(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let unknown = Int32(arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				self = .clean2(unknown, fossil)
			case "angle camera from at distance with fov: over , unknown:":
				guard arguments.count == 5 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 5, got: arguments.count, command: text)
				}
				guard let (x, y) = position(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let distance = Int32(arguments[1].replacing("0x", with: ""), radix: 16) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let fov = Int32(arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let frameCount = frames(from: arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				guard let unknown = Int32(arguments[4]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[4], command: text)
				}
				self = .angleCamera(fov: fov, xRotation: x, yRotation: y, targetDistance: distance, frameCount: frameCount, unknown)
			case "start music":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let id = Int32(arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .startMusic(id: id)
			case "fade music":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let frameCount = frames(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .fadeMusic(frameCount: frameCount)
			case "play sound":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let id = Int32(arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .playSound(id: id)
			case "effect on":
				guard arguments.count == 2 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 2, got: arguments.count, command: text)
				}
				guard let effect = Effect(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let character = Character(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				self = .characterEffect(character, effect)
			case "clear effects on":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .clearEffects(character)
			case "movement on":
				guard arguments.count == 2 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 2, got: arguments.count, command: text)
				}
				guard let movement = Movement(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let character = Character(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				self = .characterMovement(character, movement)
			case "dialogue with choice , unknown:":
				guard arguments.count == 3 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 3, got: arguments.count, command: text)
				}
				guard let dialogue = Dialogue(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let choices = Dialogue(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let unknown = Int32(arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				self = .dialogueChoice(dialogue, unknown, choices: choices)
			case "fade out image over , unknown:":
				guard arguments.count == 2 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 2, got: arguments.count, command: text)
				}
				guard let frameCount = frames(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let unknown = Int32(arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				self = .imageFadeOut(frameCount: frameCount, unknown)
			case "slide in image over , unknowns:":
				guard arguments.count == 4 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 4, got: arguments.count, command: text)
				}
				guard let image = Image(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let frameCount = frames(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let unknown1 = Int32(arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let unknown2 = Int32(arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				self = .imageSlideIn(image, unknown1, frameCount: frameCount, unknown2)
			case "fade in image over , unknowns:":
				guard arguments.count == 4 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 4, got: arguments.count, command: text)
				}
				guard let image = Image(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let frameCount = frames(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				guard let unknown1 = Int32(arguments[2]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[2], command: text)
				}
				guard let unknown2 = Int32(arguments[3]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[3], command: text)
				}
				self = .imageFadeIn(image, unknown1, frameCount: frameCount, unknown2)
			case "revive":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let vivosaur = Vivosaur(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .revive(vivosaur)
			case "start turning to follow":
				guard arguments.count == 2 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 2, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				guard let target = Character(from: arguments[1]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[1], command: text)
				}
				self = .startTurning(character, target: target)
			case "stop turning":
				guard arguments.count == 1 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				guard let character = Character(from: arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				self = .stopTurning(character)
			case "unknown:":
				guard arguments.count > 0 else {
					throw InvalidCommand.invalidNumberOfArguments(expected: 1, got: arguments.count, command: text)
				}
				
				guard let type = UInt32(arguments[0]) else {
					throw InvalidCommand.invalidArgument(argument: arguments[0], command: text)
				}
				
				let intArguments = try arguments
					.dropFirst()
					.map {
						if $0.contains("0x") {
							guard let value = Int32($0.replacing("0x", with: ""), radix: 16) else {
								throw InvalidCommand.invalidArgument(argument: $0, command: text)
							}
							return value
						} else {
							guard let value = Int32($0) else {
								throw InvalidCommand.invalidArgument(argument: $0, command: text)
							}
							return value
						}
					}
				
				self = .unknown(type: type, arguments: intArguments)
			default:
				throw InvalidCommand.invalidCommand(command: command, fullCommand: text)
		}
	}
}

extension String {
	init(_ command: DEX.Command) {
		self = switch command {
			case .dialogue(let dialogue):
				"dialogue \(dialogue)"
			case .spawn(let character, let unknown1, x: let x, y: let y, let unknown2):
				"spawn \(character) at \(position(x, y)), unknowns: \(unknowns(unknown1, unknown2))"
			case .despawn(let character):
				"despawn \(character)"
			case .fadeOut(frameCount: let frameCount):
				"fade out \(frames(frameCount))"
			case .fadeIn(frameCount: let frameCount):
				"fade in \(frames(frameCount))"
			case .unownedDialogue(let dialogue):
				"unowned dialogue \(dialogue)"
			case .turnTo(let character, angle: let angle):
				"turn \(character) to \(degrees(angle))"
			case .turn1To(let character, angle: let angle, frameCount: let frameCount, let unknown):
				"turn1 \(character) to \(degrees(angle)) over \(frames(frameCount)), unknown: <\(unknown)>"
			case .turnTowards(let character, target: let target, frameCount: let frameCount, let unknown):
				"turn \(character) towards \(target) over \(frames(frameCount)), unknown: <\(unknown)>"
			case .turn2To(let character, angle: let angle, frameCount: let frameCount, let unknown):
				"turn2 \(character) to \(degrees(angle)) over \(frames(frameCount)), unknown: <\(unknown)>"
			case .turnTowards2(let character, target: let target, let unknown1, frameCount: let frameCount, let unknown2):
				"turn \(character) towards \(target) over \(frames(frameCount)), unknowns: \(unknowns(unknown1, unknown2))"
			case .moveTo(let character, x: let x, y: let y, frameCount: let frameCount, let unknown):
				"move \(character) to \(position(x, y)) over \(frames(frameCount)), unknown: <\(unknown)>"
			case .moveBy(let character, relativeX: let relativeX, relativeY: let relativeY, frameCount: let frameCount, let unknown):
				"move \(character) by \(position(relativeX, relativeY)) over \(frames(frameCount)), unknown: <\(unknown)>"
			case .delay(frameCount: let frameCount):
				"delay \(frames(frameCount))"
			case .clean1(let unknown, let fossil):
				"clean1 \(fossil), unknown: <\(unknown)>"
			case .clean2(let unknown, let fossil):
				"clean2 \(fossil), unknown: <\(unknown)>"
			case .angleCamera(fov: let fov, xRotation: let xRotation, yRotation: let yRotation, targetDistance: let targetDistance, frameCount: let frameCount, let unknown):
				"angle camera from \(position(xRotation, yRotation)) at distance <\(String(targetDistance, radix: 16))> with fov: <\(fov)> over \(frames(frameCount)), unknown: <\(unknown)>"
			case .startMusic(id: let id):
				"start music <\(id)>"
			case .fadeMusic(frameCount: let frameCount):
				"fade music \(frames(frameCount))"
			case .playSound(id: let id):
				"play sound <\(id)>"
			case .characterEffect(let character, let effect):
				"effect \(effect) on \(character)"
			case .clearEffects(let character):
				"clear effects on \(character)"
			case .characterMovement(let character, let movement):
				"movement \(movement) on \(character)"
			case .dialogueChoice(let dialogue, let unknown, choices: let choices):
				"dialogue \(dialogue) with choice \(choices), unknown: <\(unknown)>"
			case .imageFadeOut(frameCount: let frameCount, let unknown):
				"fade out image over \(frames(frameCount)), unknown: <\(unknown)>"
			case .imageSlideIn(let image, let unknown1, frameCount: let frameCount, let unknown2):
				"slide in image \(image) over \(frames(frameCount)), unknowns: \(unknowns(unknown1, unknown2))"
			case .imageFadeIn(let image, let unknown1, frameCount: let frameCount, let unknown2):
				"fade in image \(image) over \(frames(frameCount)), unknowns: \(unknowns(unknown1, unknown2))"
			case .revive(let vivosaur):
				"revive \(vivosaur)"
			case .startTurning(let character, target: let target):
				"start turning \(character) to follow \(target)"
			case .stopTurning(let character):
				"stop turning \(character)"
			case .unknown(type: let type, arguments: let arguments):
				if arguments.isEmpty {
					"unknown: <\(type)>"
				} else {
					"unknown: <\(type)> \(unknowns(arguments, hex: arguments.contains { $0 > UInt16.max }))"
				}
		}
	}
}

fileprivate func parse(command: Substring) -> (String, [Substring]) {
	let commandRegex = try! Regex(#"(?'command'[^\n<> ]+)|<(?'argument'[\w, -]+)>"#)
	let matches = command.matches(of: commandRegex)
	
	let commandParts = matches.compactMap { $0["command"]?.substring }
	let arguments = matches.compactMap { $0["argument"]?.substring }
	
	return (
		commandParts.joined(separator: " "),
		arguments
	)
}

extension DEX.Command.Dialogue: CustomStringConvertible {
	init?(from text: Substring) {
		guard let id = Int32(text) else {
			return nil
		}
		self.id = id
	}
	
	var description: String {
		"<\(id)>"
	}
}

extension DEX.Command.Character: CustomStringConvertible {
	init?(from text: Substring) {
		guard let id = text.split(separator: " ").last.flatMap({ Int32($0) }) else {
			return nil
		}
		self.id = id
	}
	
	var description: String {
		"<character \(id)>"
	}
}

extension DEX.Command.Fossil: CustomStringConvertible {
	init?(from text: Substring) {
		guard let id = text.split(separator: " ").last.flatMap({ Int32($0) }) else {
			return nil
		}
		self.id = id
	}
	
	var description: String {
		"<fossil \(id)>"
	}
}

extension DEX.Command.Effect: CustomStringConvertible {
	init?(from text: Substring) {
		guard let id = text.split(separator: " ").last else { return nil }
		
		switch id {
			case "haha", "4":
				self = .haha
			case "threeWhiteLines", "5":
				self = .threeWhiteLines
			case "threeRedLines", "7":
				self = .threeRedLines
			case "questionMark", "8":
				self = .questionMark
			case "thinking", "9":
				self = .thinking
			case "ellipses", "22":
				self = .ellipses
			case "lightBulb", "23":
				self = .lightBulb
			default:
				guard let type = Int32(id) else { return nil }
				self = .unknown(type)
		}
	}
	
	var description: String {
		switch self {
			case .haha: "<effect haha>"
			case .threeWhiteLines: "<effect threeWhiteLines>"
			case .threeRedLines: "<effect threeRedLines>"
			case .questionMark: "<effect questionMark>"
			case .thinking: "<effect thinking>"
			case .ellipses: "<effect ellipses>"
			case .lightBulb: "<effect lightBulb>"
			case .unknown(let type): "<effect \(type)>"
		}
	}
}

extension DEX.Command.Movement: CustomStringConvertible {
	init?(from text: Substring) {
		guard let id = text.split(separator: " ").last else { return nil }
		
		switch id {
			case "jump", "1":
				self = .jump
			case "quake", "8":
				self = .quake
			default:
				guard let type = Int32(id) else { return nil }
				self = .unknown(type)
		}
	}
	
	var description: String {
		switch self {
			case .jump: "<movement jump>"
			case .quake: "<movement quake>"
			case .unknown(let type): "<movement \(type)>"
		}
	}
}

extension DEX.Command.Image: CustomStringConvertible {
	init?(from text: Substring) {
		guard let id = text.split(separator: " ").last.flatMap({ Int32($0) }) else {
			return nil
		}
		self.id = id
	}
	
	var description: String {
		"<image \(id)>"
	}
}

extension DEX.Command.Vivosaur: CustomStringConvertible {
	init?(from text: Substring) {
		guard let id = text.split(separator: " ").last.flatMap({ Int32($0) }) else {
			return nil
		}
		self.id = id
	}
	
	var description: String {
		"<vivosaur \(id)>"
	}
}

fileprivate func position(from text: Substring) -> (Int32, Int32)? {
	let coords = text.replacing("0x", with: "").split(separator: ", ")
	guard coords.count == 2,
		  let x = Int32(coords[0], radix: 16),
		  let y = Int32(coords[1], radix: 16) else { return nil }
	return (x, y)
}

fileprivate func position(_ x: Int32, _ y: Int32) -> String {
	"<\(hex(x)), \(hex(y))>"
}

fileprivate func hex<T: BinaryInteger & SignedNumeric>(_ value: T) -> String {
	if value < 0 {
		"-0x\(String(-value, radix: 16))"
	} else {
		"0x\(String(value, radix: 16))"
	}
}

fileprivate func unknowns(_ unknowns: Int32...) -> String {
	unknowns.map { "<\($0)>" }.joined(separator: " ")
}

fileprivate func unknowns(_ unknowns: [Int32], hex isHex: Bool = false) -> String {
	if isHex {
		unknowns.map { "<0x\(String($0, radix: 16))>" }.joined(separator: " ")
	} else {
		unknowns.map { "<\($0)>" }.joined(separator: " ")
	}
}

fileprivate func frames(from text: Substring) -> Int32? {
	text
		.split(separator: " ")
		.first
		.flatMap({ Int32($0) })
}

fileprivate func frames(_ frameCount: Int32) -> String {
	"<\(frameCount) frames>"
}

fileprivate func degrees(from text: Substring) -> Int32? {
	text
		.split(separator: " ")
		.first
		.flatMap({ Int32($0) })
}

fileprivate func degrees(_ angle: Int32) -> String {
	"<\(angle) degrees>"
}
