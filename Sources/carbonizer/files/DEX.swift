import BinaryParser
import Foundation

struct DEX: Codable, Writeable {
	var commands: [[Command]]
	
	struct Command: Codable {
		var type: UInt32
		var arguments: [Int32]
	}
	
	@BinaryConvertible
	struct Binary: Writeable {
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
	static var packedFileExtension = ""
	static var unpackedFileExtension = "dex.json"
	
	init(packed: Binary) {
		commands = packed.script
			.map(\.commands)
			.recursiveMap(Command.init)
	}
}

extension DEX.Command {
	init(_ commandBinary: DEX.Binary.Scene.Command) {
		type = commandBinary.type
		arguments = commandBinary.arguments
	}
}

extension DEX.Binary: InitFrom {
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
extension DEX {
	init(from decoder: Decoder) throws {
		commands = try [[Command]](from: decoder)
	}
	
	func encode(to encoder: Encoder) throws {
		try commands.encode(to: encoder)
	}
}

// TODO: find a way to use this - BinaryConvertible enums ?
//enum Command: Codable {
//	case dialogue(Dialogue)
//	case spawn(Character, Int32, x: Int32, y: Int32, Int32)
//	case despawn(Character)
//	case fadeOut(frameCount: Int32)
//	case fadeIn(frameCount: Int32)
//	case unownedDialogue(Dialogue)
//	case turnTo(Character, angle: Int32)
//	case turn1To(Character, angle: Int32, frameCount: Int32, Int32)
//	case turnTowards(Character, target: Character, frameCount: Int32, Int32)
//	case turn2To(Character, angle: Int32, frameCount: Int32, Int32)
//	case turnTowards2(Character, target: Character, Int32, frameCount: Int32, Int32)
//	case moveTo(Character, x: Int32, y: Int32, frameCount: Int32, Int32)
//	case moveBy(Character, relativeX: Int32, relativeY: Int32, frameCount: Int32, Int32)
//	case delay(frameCount: Int32)
//	case clean1(Int32, Fossil)
//	case clean2(Int32, Fossil)
//	case angleCamera(fov: Int32, xRotation: Int32, yRotation: Int32, targetDistance: Int32, frameCount: Int32, Int32)
//	case startMusic(id: Int32)
//	case fadeMusic(frameCount: Int32)
//	case playSound(id: Int32)
//	case characterEffect(Character, Effect)
//	case clearEffects(Character)
//	case characterMovement(Character, Movement)
//	case dialogueChoice(Dialogue, Int32, choices: Dialogue)
//	case imageFadeOut(frameCount: Int32, Int32)
//	case imageSlideIn(Image, Int32, frameCount: Int32, Int32)
//	case imageFadeIn(Image, Int32, frameCount: Int32, Int32)
//	case revive(Vivosaur)
//	case startTurning(Character, target: Character)
//	case stopTurning(Character)
//	
//	case unknown(type: UInt32, arguments: [Int32])
//	
//	struct Dialogue: Codable {
//		var id: Int32
//		init(_ id: Int32) { self.id = id }
//	}
//	
//	struct Character: Codable {
//		var id: Int32
//		init(_ id: Int32) { self.id = id }
//	}
//	
//	struct Fossil: Codable {
//		var id: Int32
//		init(_ id: Int32) { self.id = id }
//	}
//	
//	enum Effect: Codable {
//		case haha
//		case threeWhiteLines
//		case threeRedLines
//		case questionMark
//		case thinking
//		case ellipses
//		case lightBulb
//		case unknown(Int32)
//		
//		init(_ type: Int32) {
//			self = switch type {
//				case 4:  .haha
//				case 5:  .threeWhiteLines
//				case 7:  .threeRedLines
//				case 8:  .questionMark
//				case 9:  .thinking
//				case 22: .ellipses
//				case 23: .lightBulb
//				default: .unknown(type)
//			}
//		}
//	}
//	
//	enum Movement: Codable {
//		case jump
//		case quake
//		case unknown(Int32)
//		
//		init(_ type: Int32) {
//			self = switch type {
//				case 1:  .jump
//				case 8:  .quake
//				default: .unknown(type)
//			}
//		}
//	}
//
//	struct Image: Codable {
//		var id: Int32
//		init(_ id: Int32) { self.id = id }
//	}
//	
//	struct Vivosaur: Codable {
//		var id: Int32
//		init(_ id: Int32) { self.id = id }
//	}
//	
//	init(_ commandBinary: DEX.Binary.Scene.Command) {
//		let args = commandBinary.arguments
//		self = switch commandBinary.type {
//			case 1: .dialogue(Dialogue(args[0]))
//			case 7: .spawn(Character(args[0]), args[1], x: args[2], y: args[3], args[4])
//			case 14: .despawn(Character(args[0]))
//			case 20: .fadeOut(frameCount: args[0])
//			case 21: .fadeIn(frameCount: args[0])
//			case 32: .unownedDialogue(Dialogue(args[0]))
//			case 34: .turnTo(Character(args[0]), angle: args[1])
//			case 35: .turn1To(Character(args[0]), angle: args[1], frameCount: args[2], args[3])
//			case 36: .turnTowards(Character(args[0]), target: Character(args[1]), frameCount: args[2], args[3])
//			case 37: .turn2To(Character(args[0]), angle: args[1], frameCount: args[2], args[3])
//			case 38: .turnTowards2(Character(args[0]), target: Character(args[1]), args[2], frameCount: args[3], args[4])
//			case 43: .moveTo(Character(args[0]), x: args[1], y: args[2], frameCount: args[3], args[4])
//			case 45: .moveBy(Character(args[0]), relativeX: args[1], relativeY: args[2], frameCount: args[3], args[4])
//			case 56: .delay(frameCount: args[0])
//			case 58: .clean1(args[0], Fossil(args[1]))
//			case 59: .clean2(args[0], Fossil(args[1]))
//			case 61: .angleCamera(fov: args[0], xRotation: args[1], yRotation: args[2], targetDistance: args[3], frameCount: args[4], args[5])
//			case 117: .startMusic(id: args[0])
//			case 124: .fadeMusic(frameCount: args[0])
//			case 125: .playSound(id: args[0])
//			case 129: .characterEffect(Character(args[0]), Effect(args[1]))
//			case 131: .clearEffects(Character(args[0]))
//			case 135: .characterMovement(Character(args[0]), Movement(args[1]))
//			case 144: .dialogueChoice(Dialogue(args[0]), args[1], choices: Dialogue(args[2]))
//			case 154: .imageFadeOut(frameCount: args[0], args[1])
//			case 155: .imageSlideIn(Image(args[0]), args[1], frameCount: args[2], args[3])
//			case 157: .imageFadeIn(Image(args[0]), args[1], frameCount: args[2], args[3])
//			case 191: .revive(Vivosaur(args[0]))
//			case 200: .startTurning(Character(args[0]), target: Character(args[1]))
//			case 201: .stopTurning(Character(args[0]))
//			default: .unknown(type: commandBinary.type, arguments: args)
//		}
//	}
//}
