import BinaryParser
import Foundation

struct DEX {
	var commands: [[Command]]
	
	
	// 22: fade to white (frames)
	// 23 fade out from white (frames)
	// 114 character model - sets which model for the characters body
	// 115 character model - sets which model for the characters head
	// 142 - modify name
	// 143 - set name
	// 41 - moveTo 2 (character) (position) (unknown)
	// 138 - screen shake (how much it shakes) (gradual intensity) (duration)
	// 57 - battle (unknown) (battle id)
	
	// 33 dialogue choice with help text??????????
	
	// unknown <3>: <7025> freezes camera focus
	
	// 50 ???? smoothes out movement or something
	// 62 does something similar - camera goes to the wrong place without it
	// 153 blanks out the screen (used before asking for name FIRST TIME)
	
	// 3: unknown (unknown)
	// 6: unknown (0x5######)
	// 8: unknown (unknown, unknown)
	// 50: unknown (character)
	// 51: unknown (character)
	// 116: unknown (unknown)
	// 118: unknown ()
	// 120: unknown ()
	// 178: suppresses "Fighter Area" corner tag
	// 194: unknown (character)
	enum Command {
		case dialogue(Dialogue)
		case spawn(Character, Map, position: Vector, Angle)
		case teleport(Character, to: Character)
		case despawn(Character)
		case fadeOut(FrameCount)
		case fadeIn(FrameCount)
		case unownedDialogue(Dialogue)
		case turnTo(Character, Angle)
		case turn1To(Character, Angle, FrameCount, Unknown)
		case turnTowards(Character, target: Character, FrameCount, Unknown)
		case turn2To(Character, Angle, FrameCount, Unknown)
		case turnTowards2(Character, target: Character, Unknown, FrameCount, Unknown)
		case move(Character, to: Character, FrameCount, Unknown)
		case moveTo(Character, position: Vector, FrameCount, Unknown)
		case moveBy(Character, relative: Vector, FrameCount, Unknown)
		case control(Character)
		case delay(FrameCount)
		case clean1(Unknown, Fossil)
		case clean2(Unknown, Fossil)
		case angleCamera(fov: FixedPoint, rotation: Vector, targetDistance: FixedPoint, FrameCount, Unknown)
		case startMusic(id: Music)
		case fadeMusic(FrameCount)
		case playSound(id: SoundEffect)
		case characterEffect(Character, Effect)
		case clearEffects(Character)
		case characterMovement(Character, Movement)
		case dialogueChoice(Dialogue, Unknown, choices: Dialogue)
		case imageFadeOut(FrameCount, Unknown)
		case imageSlideIn(Image, Unknown, FrameCount, Unknown)
		case imageFadeIn(Image, Unknown, FrameCount, Unknown)
		case revive(Vivosaur)
		case startTurning(Character, target: Character)
		case stopTurning(Character)
		
		case unknown(type: UInt32, arguments: [Unknown])
		
		case comment(String)
		
		struct Argument<Unit: UnitProtocol> {
			var value: Int32
			init(_ value: Int32) { self.value = value }
		}
		
		typealias Angle = Argument<DegreeUnit>
		typealias Character = Argument<CharacterUnit>
		typealias Dialogue = Argument<DialogueUnit>
		typealias Effect = Argument<EffectUnit>
		typealias Fossil = Argument<FossilUnit>
		typealias FixedPoint = Argument<FixedPointUnit>
		typealias FrameCount = Argument<FrameUnit>
		typealias Image = Argument<ImageUnit>
		typealias Map = Argument<MapUnit>
		typealias Movement = Argument<MovementUnit>
		typealias Music = Argument<MusicUnit>
		typealias SoundEffect = Argument<SoundEffectUnit>
		typealias Unknown = Argument<UnknownUnit>
		typealias Vivosaur = Argument<VivosaurUnit>
		
		struct Vector {
			var x: Int32
			var y: Int32
		}
		
		enum InvalidCommand: Error {
			case invalidCommand(Substring)
			case invalidNumberOfArguments(expected: Int, got: Int, command: Substring)
			case invalidArgument(argument: Substring, command: Substring)
		}
	}
	
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "DEX"
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

extension DEX: ProprietaryFileData {
	static let fileExtension = ".dex.txt"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	init(_ binary: Binary) {
		commands = binary.script
			.map(\.commands)
			.recursiveMap(Command.init)
	}
	
	init(_ data: Datastream) throws {
		let fileLength = data.bytes.endIndex - data.offset
		let string = try data.read(String.self, exactLength: fileLength)
		
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
		
		data.write(string, length: string.lengthOfBytes(using: .utf8))
	}
}

extension DEX.Binary: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	init(_ dex: DEX) {
		numberOfScenes = UInt32(dex.commands.count)
		
		script = dex.commands.map(Scene.init)
		
		sceneOffsets = createOffsets(
			start: sceneOffsetsStart + numberOfScenes * 4,
			sizes: script.map { $0.size() }
		)
	}
}

extension DEX.Command {
	init(_ commandBinary: DEX.Binary.Scene.Command) {
		let args = commandBinary.arguments
		self = switch commandBinary.type {
			case 1:  .dialogue(Dialogue(args[0]))
			case 7:  .spawn(Character(args[0]), Map(args[1]), position: Vector(x: args[2], y: args[3]), Angle(args[4]))
			case 10: .teleport(Character(args[0]), to: Character(args[1]))
			case 14: .despawn(Character(args[0]))
			case 20: .fadeOut(FrameCount(args[0]))
			case 21: .fadeIn(FrameCount(args[0]))
			case 32: .unownedDialogue(Dialogue(args[0]))
			case 34: .turnTo(Character(args[0]), Angle(args[1]))
			case 35: .turn1To(Character(args[0]), Angle(args[1]), FrameCount(args[2]), Unknown(args[3]))
			case 36: .turnTowards(Character(args[0]), target: Character(args[1]), FrameCount(args[2]), Unknown(args[3]))
			case 37: .turn2To(Character(args[0]), Angle(args[1]), FrameCount(args[2]), Unknown(args[3]))
			case 38: .turnTowards2(Character(args[0]), target: Character(args[1]), Unknown(args[2]), FrameCount(args[3]), Unknown(args[4]))
			case 39: .move(Character(args[0]), to: Character(args[1]), FrameCount(args[2]), Unknown(args[3]))
			case 43: .moveTo(Character(args[0]), position: Vector(x: args[1], y: args[2]), FrameCount(args[3]), Unknown(args[4]))
			case 45: .moveBy(Character(args[0]), relative: Vector(x: args[1], y: args[2]), FrameCount(args[3]), Unknown(args[4]))
			case 51: .control(Character(args[0]))
			case 56: .delay(FrameCount(args[0]))
			case 58: .clean1(Unknown(args[0]), Fossil(args[1]))
			case 59: .clean2(Unknown(args[0]), Fossil(args[1]))
			case 61: .angleCamera(fov: FixedPoint(args[0]), rotation: Vector(x: args[1], y: args[2]), targetDistance: FixedPoint(args[3]), FrameCount(args[4]), Unknown(args[5]))
			case 117: .startMusic(id: Music(args[0]))
			case 124: .fadeMusic(FrameCount(args[0]))
			case 125: .playSound(id: SoundEffect(args[0]))
			case 129: .characterEffect(Character(args[0]), Effect(args[1]))
			case 131: .clearEffects(Character(args[0]))
			case 135: .characterMovement(Character(args[0]), Movement(args[1]))
			case 144: .dialogueChoice(Dialogue(args[0]), Unknown(args[1]), choices: Dialogue(args[2]))
			case 154: .imageFadeOut(FrameCount(args[0]), Unknown(args[1]))
			case 155: .imageSlideIn(Image(args[0]), Unknown(args[1]), FrameCount(args[2]), Unknown(args[3]))
			case 157: .imageFadeIn(Image(args[0]), Unknown(args[1]), FrameCount(args[2]), Unknown(args[3]))
			case 191: .revive(Vivosaur(args[0]))
			case 200: .startTurning(Character(args[0]), target: Character(args[1]))
			case 201: .stopTurning(Character(args[0]))
			default:  .unknown(type: commandBinary.type, arguments: args.map(Unknown.init))
		}
	}
	
	var typeAndArguments: (UInt32, [Int32])? {
		switch self {
			case .dialogue(let dialogue):
				(1, [dialogue.value])
			case .spawn(let character, let unknown, let position, let angle):
				(7, [character.value, unknown.value, position.x, position.y, angle.value])
			case .teleport(let source, to: let destination):
				(10, [source.value, destination.value])
			case .despawn(let character):
				(14, [character.value])
			case .fadeOut(let frames):
				(20, [frames.value])
			case .fadeIn(let frames):
				(21, [frames.value])
			case .unownedDialogue(let dialogue):
				(32, [dialogue.value])
			case .turnTo(let character, let angle):
				(34, [character.value, angle.value])
			case .turn1To(let character, let angle, let frames, let unknown):
				(35, [character.value, angle.value, frames.value, unknown.value])
			case .turnTowards(let character, let target, let frames, let unknown):
				(36, [character.value, target.value, frames.value, unknown.value])
			case .turn2To(let character, let angle, let frames, let unknown):
				(37, [character.value, angle.value, frames.value, unknown.value])
			case .turnTowards2(let character, let target, let unknown1, let frames, let unknown2):
				(38, [character.value, target.value, unknown1.value, frames.value, unknown2.value])
			case .move(let source, to: let destination, let frames, let unknown):
				(39, [source.value, destination.value, frames.value, unknown.value])
			case .moveTo(let character, let position, let frames, let unknown):
				(43, [character.value, position.x, position.y, frames.value, unknown.value])
			case .moveBy(let character, let relative, let frames, let unknown):
				(45, [character.value, relative.x, relative.y, frames.value, unknown.value])
			case .control(let character):
				(51, [character.value])
			case .delay(let frames):
				(56, [frames.value])
			case .clean1(let unknown, let fossil):
				(58, [unknown.value, fossil.value])
			case .clean2(let unknown, let fossil):
				(59, [unknown.value, fossil.value])
			case .angleCamera(let fov, let rotation, let targetDistance, let frames, let unknown):
				(61, [fov.value, rotation.x, rotation.y, targetDistance.value, frames.value, unknown.value])
			case .startMusic(let id):
				(117, [id.value])
			case .fadeMusic(let frames):
				(124, [frames.value])
			case .playSound(let soundEffect):
				(125, [soundEffect.value])
			case .characterEffect(let character, let effect):
				(129, [character.value, effect.value])
			case .clearEffects(let character):
				(131, [character.value])
			case .characterMovement(let character, let movement):
				(135, [character.value, movement.value])
			case .dialogueChoice(let dialogue, let unknown, let choices):
				(144, [dialogue.value, unknown.value, choices.value])
			case .imageFadeOut(let frames, let unknown):
				(154, [frames.value, unknown.value])
			case .imageSlideIn(let image, let unknown1, let frames, let unknown2):
				(155, [image.value, unknown1.value, frames.value, unknown2.value])
			case .imageFadeIn(let image, let unknown1, let frames, let unknown2):
				(157, [image.value, unknown1.value, frames.value, unknown2.value])
			case .revive(let vivosaur):
				(191, [vivosaur.value])
			case .startTurning(let character, let target):
				(200, [character.value, target.value])
			case .stopTurning(let character):
				(201, [character.value])
			case .unknown(let type, let arguments):
				(type, arguments.map(\.value))
			case .comment: nil
		}
	}
	
	init(_ text: Substring) throws {
		let (command, arguments) = try parse(command: text)
		
		if let expectedArgumentCount = command.argumentCount {
			guard arguments.count == expectedArgumentCount else {
				throw InvalidCommand.invalidNumberOfArguments(
					expected: expectedArgumentCount,
					got: arguments.count,
					command: text
				)
			}
		} else if case .unknown = command {
			guard arguments.count > 0 else {
				throw InvalidCommand.invalidNumberOfArguments(
					expected: 1,
					got: arguments.count,
					command: text
				)
			}
		}
		
		func invalidArgument(_ argumentNumber: Int) -> some Error {
			InvalidCommand.invalidArgument(argument: arguments[argumentNumber], command: text)
		}
		
		self = switch command {
			case .dialogue: .dialogue(
				try Dialogue(arguments[0]).orElseThrow(invalidArgument(0))
			)
			case .spawn: .spawn(
				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
				try Map(arguments[1]).orElseThrow(invalidArgument(2)),
				position: try Vector(arguments[2]).orElseThrow(invalidArgument(1)),
				try Angle(arguments[3]).orElseThrow(invalidArgument(3))
			)
			case .teleport: .teleport(
				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
				to: try Character(arguments[1]).orElseThrow(invalidArgument(1))
			)
			case .despawn: .despawn(
				try Character(arguments[0]).orElseThrow(invalidArgument(0))
			)
			case .fadeOut: .fadeOut(
				try FrameCount(arguments[0]).orElseThrow(invalidArgument(0))
			)
			case .fadeIn: .fadeIn(
				try FrameCount(arguments[0]).orElseThrow(invalidArgument(0))
			)
			case .unownedDialogue: .unownedDialogue(
				try Dialogue(arguments[0]).orElseThrow(invalidArgument(0))
			)
			case .turnTo: .turnTo(
				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
				try Angle(arguments[1]).orElseThrow(invalidArgument(1))
			)
			case .turn1To: .turn1To(
				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
				try Angle(arguments[1]).orElseThrow(invalidArgument(1)),
				try FrameCount(arguments[2]).orElseThrow(invalidArgument(2)),
				try Unknown(arguments[3]).orElseThrow(invalidArgument(3))
			)
			case .turnTowards: .turnTowards(
				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
				target: try Character(arguments[1]).orElseThrow(invalidArgument(1)),
				try FrameCount(arguments[2]).orElseThrow(invalidArgument(2)),
				try Unknown(arguments[3]).orElseThrow(invalidArgument(3))
			)
			case .turn2To: .turn2To(
				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
				try Angle(arguments[1]).orElseThrow(invalidArgument(1)),
				try FrameCount(arguments[2]).orElseThrow(invalidArgument(2)),
				try Unknown(arguments[3]).orElseThrow(invalidArgument(3))
			)
			case .turnTowards2: .turnTowards2(
				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
				target: try Character(arguments[1]).orElseThrow(invalidArgument(1)),
				try Unknown(arguments[3]).orElseThrow(invalidArgument(3)),
				try FrameCount(arguments[2]).orElseThrow(invalidArgument(2)),
				try Unknown(arguments[4]).orElseThrow(invalidArgument(4))
			)
			case .move: .move(
				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
				to: try Character(arguments[1]).orElseThrow(invalidArgument(1)),
				try FrameCount(arguments[2]).orElseThrow(invalidArgument(2)),
				try Unknown(arguments[3]).orElseThrow(invalidArgument(3))
			)
			case .moveTo: .moveTo(
				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
				position: try Vector(arguments[1]).orElseThrow(invalidArgument(1)),
				try FrameCount(arguments[2]).orElseThrow(invalidArgument(2)),
				try Unknown(arguments[3]).orElseThrow(invalidArgument(3))
			)
			case .moveBy: .moveBy(
				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
				relative: try Vector(arguments[1]).orElseThrow(invalidArgument(1)),
				try FrameCount(arguments[2]).orElseThrow(invalidArgument(2)),
				try Unknown(arguments[3]).orElseThrow(invalidArgument(3))
			)
			case .control: .control(
				try Character(arguments[0]).orElseThrow(invalidArgument(0))
			)
			case .delay: .delay(
				try FrameCount(arguments[0]).orElseThrow(invalidArgument(0))
			)
			case .clean1: .clean1(
				try Unknown(arguments[1]).orElseThrow(invalidArgument(1)),
				try Fossil(arguments[0]).orElseThrow(invalidArgument(0))
			)
			case .clean2: .clean2(
				try Unknown(arguments[1]).orElseThrow(invalidArgument(1)),
				try Fossil(arguments[0]).orElseThrow(invalidArgument(0))
			)
			case .angleCamera: .angleCamera(
				fov: try FixedPoint(arguments[2]).orElseThrow(invalidArgument(2)),
				rotation: try Vector(arguments[0]).orElseThrow(invalidArgument(0)),
				targetDistance: try FixedPoint(arguments[1]).orElseThrow(invalidArgument(1)),
				try FrameCount(arguments[3]).orElseThrow(invalidArgument(3)),
				try Unknown(arguments[4]).orElseThrow(invalidArgument(4))
			)
			case .startMusic: .startMusic(
				id: try Music(arguments[0]).orElseThrow(invalidArgument(0))
			)
			case .fadeMusic: .fadeMusic(
				try FrameCount(arguments[0]).orElseThrow(invalidArgument(0))
			)
			case .playSound: .playSound(
				id: try SoundEffect(arguments[0]).orElseThrow(invalidArgument(0))
			)
			case .characterEffect: .characterEffect(
				try Character(arguments[1]).orElseThrow(invalidArgument(1)),
				try Effect(arguments[0]).orElseThrow(invalidArgument(0))
			)
			case .clearEffects: .clearEffects(
				try Character(arguments[0]).orElseThrow(invalidArgument(0))
			)
			case .characterMovement: .characterMovement(
				try Character(arguments[1]).orElseThrow(invalidArgument(1)),
				try Movement(arguments[0]).orElseThrow(invalidArgument(0))
			)
			case .dialogueChoice: .dialogueChoice(
				try Dialogue(arguments[0]).orElseThrow(invalidArgument(0)),
				try Unknown(arguments[2]).orElseThrow(invalidArgument(2)),
				choices: try Dialogue(arguments[1]).orElseThrow(invalidArgument(1))
			)
			case .imageFadeOut: .imageFadeOut(
				try FrameCount(arguments[0]).orElseThrow(invalidArgument(0)),
				try Unknown(arguments[1]).orElseThrow(invalidArgument(1))
			)
			case .imageSlideIn: .imageSlideIn(
				try Image(arguments[0]).orElseThrow(invalidArgument(0)),
				try Unknown(arguments[2]).orElseThrow(invalidArgument(2)),
				try FrameCount(arguments[1]).orElseThrow(invalidArgument(1)),
				try Unknown(arguments[3]).orElseThrow(invalidArgument(3))
			)
			case .imageFadeIn: .imageFadeIn(
				try Image(arguments[0]).orElseThrow(invalidArgument(0)),
				try Unknown(arguments[2]).orElseThrow(invalidArgument(2)),
				try FrameCount(arguments[1]).orElseThrow(invalidArgument(1)),
				try Unknown(arguments[3]).orElseThrow(invalidArgument(3))
			)
			case .revive: .revive(
				try Vivosaur(arguments[0]).orElseThrow(invalidArgument(0))
			)
			case .startTurning: .startTurning(
				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
				target: try Character(arguments[1]).orElseThrow(invalidArgument(1))
			)
			case .stopTurning: .stopTurning(
				try Character(arguments[0]).orElseThrow(invalidArgument(0))
			)
			case .unknown: .unknown(
				type: try UInt32(arguments[0]).orElseThrow(invalidArgument(0)),
				arguments: try arguments
					.enumerated()
					.dropFirst()
					.map { try Unknown($0.element).orElseThrow(invalidArgument($0.offset)) }
			)
			case .comment: .comment(String(text.dropFirst(3)))
		}
	}
	
	var isNotComment: Bool {
		switch self {
			case .comment: false
			default: true
		}
	}
}

extension String {
	init(_ command: DEX.Command) {
		self = switch command {
			case .dialogue(let dialogue):
				"dialogue \(dialogue)"
			case .spawn(let character, let map, let position, let angle):
				"spawn \(character) in \(map) at \(position) facing \(angle)"
			case .teleport(let source, to: let destination):
				"teleport \(source) to \(destination)"
			case .despawn(let character):
				"despawn \(character)"
			case .fadeOut(frameCount: let frameCount):
				"fade out \(frameCount)"
			case .fadeIn(frameCount: let frameCount):
				"fade in \(frameCount)"
			case .unownedDialogue(let dialogue):
				"unowned dialogue \(dialogue)"
			case .turnTo(let character, let angle):
				"turn \(character) to \(angle)"
			case .turn1To(let character, let angle, let frameCount, let unknown):
				"turn1 \(character) to \(angle) over \(frameCount), unknown: \(unknown)"
			case .turnTowards(let character, target: let target, let frameCount, let unknown):
				"turn \(character) towards \(target) over \(frameCount), unknown: \(unknown)"
			case .turn2To(let character, let angle, let frameCount, let unknown):
				"turn2 \(character) to \(angle) over \(frameCount), unknown: \(unknown)"
			case .turnTowards2(let character, target: let target, let unknown1, let frameCount, let unknown2):
				"turn \(character) towards \(target) over \(frameCount), unknowns: \(unknown1) \(unknown2)"
			case .move(let source, to: let destination, let frameCount, let unknown):
				"move \(source) to \(destination) over \(frameCount), unknown: \(unknown)"
			case .moveTo(let character, let position, let frameCount, let unknown):
				"move \(character) to \(position) over \(frameCount), unknown: \(unknown)"
			case .moveBy(let character, relative: let relative, let frameCount, let unknown):
				"move \(character) by \(relative) over \(frameCount), unknown: \(unknown)"
			case .control(let character):
				"control \(character)"
			case .delay(frameCount: let frameCount):
				"delay \(frameCount)"
			case .clean1(let unknown, let fossil):
				"clean1 \(fossil), unknown: \(unknown)"
			case .clean2(let unknown, let fossil):
				"clean2 \(fossil), unknown: \(unknown)"
			case .angleCamera(fov: let fov, rotation: let rotation, targetDistance: let targetDistance, let frameCount, let unknown):
				"angle camera from \(rotation) at distance \(targetDistance) with fov: \(fov) over \(frameCount), unknown: \(unknown)"
			case .startMusic(id: let id):
				"start music \(id)"
			case .fadeMusic(frameCount: let frameCount):
				"fade music \(frameCount)"
			case .playSound(id: let id):
				"play sound \(id)"
			case .characterEffect(let character, let effect):
				"effect \(effect) on \(character)"
			case .clearEffects(let character):
				"clear effects on \(character)"
			case .characterMovement(let character, let movement):
				"movement \(movement) on \(character)"
			case .dialogueChoice(let dialogue, let unknown, choices: let choices):
				"dialogue \(dialogue) with choice \(choices), unknown: \(unknown)"
			case .imageFadeOut(let frameCount, let unknown):
				"fade out image over \(frameCount), unknown: \(unknown)"
			case .imageSlideIn(let image, let unknown1, let frameCount, let unknown2):
				"slide in image \(image) over \(frameCount), unknowns: \(unknown1) \(unknown2)"
			case .imageFadeIn(let image, let unknown1, let frameCount, let unknown2):
				"fade in image \(image) over \(frameCount), unknowns: \(unknown1) \(unknown2)"
			case .revive(let vivosaur):
				"revive \(vivosaur)"
			case .startTurning(let character, target: let target):
				"start turning \(character) to follow \(target)"
			case .stopTurning(let character):
				"stop turning \(character)"
			case .unknown(type: let type, arguments: let arguments):
				if arguments.isEmpty {
					"unknown <\(type)>"
				} else {
					"unknown <\(type)>: \(arguments.map(\.description).joined(separator: " "))"
				}
			case .comment(let text):
				"// \(text)"
		}
	}
}

extension DEX.Command.Argument: CustomStringConvertible {
	init?(_ text: Substring) {
		guard let value = Unit.parse(text) else { return nil }
		self.value = value
	}
	
	var description: String {
		"<\(Unit.format(value))>"
	}
}

extension DEX.Command.Vector: CustomStringConvertible {
	init?(_ text: Substring) {
		let coords = text.split(separator: ", ")
		guard coords.count == 2,
			  let x = FixedPointUnit.parse(coords[0]),
			  let y = FixedPointUnit.parse(coords[1]) else { return nil }
		
		self.x = x
		self.y = y
	}
	
	var description: String {
		"<\(FixedPointUnit.format(x)), \(FixedPointUnit.format(y))>"
	}
}

enum CommandType {
	case dialogue, spawn, teleport, despawn, fadeOut, fadeIn, unownedDialogue, turnTo, turn1To, turnTowards, turn2To, turnTowards2, move, moveTo, moveBy, control, delay, clean1, clean2, angleCamera, startMusic, fadeMusic, playSound, characterEffect, clearEffects, characterMovement, dialogueChoice, imageFadeOut, imageSlideIn, imageFadeIn, revive, startTurning, stopTurning, unknown, comment
	
	init?(_ command: Substring) {
		let firstSpace = command.firstIndex(where: \.isWhitespace)
		guard let firstSpace else { return nil }
		let firstWord = command[..<firstSpace]
		
		let possiblySelf: Self? = switch firstWord {
			case "dialogue":
				if command.contains("choice") {
					.dialogueChoice
				} else {
					.dialogue
				}
			case "spawn": .spawn
			case "teleport": .teleport
			case "despawn": .despawn
			case "fade":
				if command.contains("image") {
					if command.contains("in") {
						.imageFadeIn
					} else {
						.imageFadeOut
					}
				} else if command.contains("music") {
					.fadeMusic
				} else {
					if command.contains("in") {
						.fadeIn
					} else {
						.fadeOut
					}
				}
			case "unowned": .unownedDialogue
			case "turn":
				if command.contains("unknowns") {
					.turnTowards2
				} else if command.contains("unknown") {
					.turnTowards
				} else {
					.turnTo
				}
			case "turn1": .turn1To
			case "turn2": .turn2To
			case "move":
				if command.contains("to") {
					if command.count(where: { $0 == "," }) > 1 {
						.moveTo
					} else {
						.move
					}
				} else {
					.moveBy
				}
			case "control": .control
			case "delay": .delay
			case "clean1": .clean1
			case "clean2": .clean2
			case "angle": .angleCamera
			case "start":
				if command.contains("music") {
					.startMusic
				} else {
					.startTurning
				}
			case "play": .playSound
			case "effect": .characterEffect
			case "clear": .clearEffects
			case "movement": .characterMovement
			case "slide": .imageSlideIn
			case "revive": .revive
			case "stop": .stopTurning
			case "unknown": .unknown
			case "//": .comment
			default: nil
		}
		
		guard let possiblySelf else { return nil }
		self = possiblySelf
	}
	
	var argumentCount: Int? {
		switch self {
			case .dialogue, .despawn, .fadeOut, .fadeIn, .unownedDialogue, .control, .delay, .startMusic, .fadeMusic, .playSound, .clearEffects, .revive, .stopTurning: 1
			case .teleport, .turnTo, .clean1, .clean2, .characterEffect, .characterMovement, .imageFadeOut, .startTurning: 2
			case .dialogueChoice: 3
			case .move, .moveTo, .moveBy, .spawn, .turn1To, .turnTowards, .turn2To, .imageSlideIn, .imageFadeIn: 4
			case .turnTowards2, .angleCamera: 5
			case .unknown, .comment: nil
		}
	}
}

fileprivate func parse(command commandText: Substring) throws -> (CommandType, [Substring]) {
	guard let command = CommandType(commandText) else {
		throw DEX.Command.InvalidCommand.invalidCommand(commandText)
	}
	
	// TODO: switch once swift 6 is out
//	let argumentStartIndices = commandText
//		.indices(of: "<")
//		.ranges
//		.map(\.upperBound)
//	let argumentEndIndices = commandText
//		.indices(of: ">")
//		.ranges
//		.map(\.lowerBound)
	
	let argumentStartIndices = commandText
		.myIndices(of: "<")
		.map(\.upperBound)
	let argumentEndIndices = commandText
		.myIndices(of: ">")
		.map(\.lowerBound)
	
	let arguments = zip(argumentStartIndices, argumentEndIndices)
		.map { startIndex, endIndex in
			commandText[startIndex..<endIndex]
		}
	
	return (command, arguments)
}
