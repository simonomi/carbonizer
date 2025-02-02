import BinaryParser
import Foundation

struct DEX {
	var commands: [[Command]]
	
	enum ArgumentType {
		case character, degrees, dialogue, effect, fixedPoint, fossil, frames, image, map, movement, music, soundEffect, unknown, vivosaur
	}
	
	// TODO: move conformance/impl to extension
	struct CommandDefinition: ExpressibleByStringInterpolation {
		var argumentTypes: [ArgumentType]
		var outputStringThingy: [OutputStringThingyChunk]
		var textWithoutArguments: [String]
		var argumentIndicesFromText: [Int] // this is the mapping of the binary order to text order TODO: rename
		
		enum OutputStringThingyChunk {
			case text(String)
			case argument(Int)
			case vector(Int, Int)
			
			init(_ stringInterpolationChunk: StringInterpolation.Chunk) {
				self = switch stringInterpolationChunk {
					case .text(let text): .text(text)
					case .argument(let index, _): .argument(index)
					case .vector(let index1, let index2): .vector(index1, index2)
				}
			}
		}
		
		struct StringInterpolation: StringInterpolationProtocol {
			var chunks: [Chunk]
			
			enum Chunk {
				case text(String)
				case argument(Int, ArgumentType)
				case vector(Int, Int)
			}
			
			init(literalCapacity: Int, interpolationCount: Int) {
				chunks = []
				chunks.reserveCapacity(interpolationCount)
			}
			
			mutating func appendLiteral(_ literal: String) {
				chunks.append(.text(literal))
			}
			
			mutating func appendInterpolation(_ argumentNumber: Int, _ argumentType: ArgumentType) {
				chunks.append(.argument(argumentNumber, argumentType))
			}
			
			enum VectorType {
				case vector
			}
			
			mutating func appendInterpolation(_ argumentOne: Int, _ argumentTwo: Int, _: VectorType) {
				chunks.append(.vector(argumentOne, argumentTwo))
			}
		}
		
		init(stringLiteral value: String) {
			argumentTypes = []
			outputStringThingy = [.text(value)]
			textWithoutArguments = [value]
			argumentIndicesFromText = []
		}
		
		init(stringInterpolation: StringInterpolation) {
			argumentTypes = stringInterpolation.chunks
				.flatMap { (chunk: StringInterpolation.Chunk) -> [(index: Int, argumentType: ArgumentType)] in
					switch chunk {
						case .text: []
						case .argument(let index, let argumentType): [(index, argumentType)]
						case .vector(let index1, let index2): [(index1, .fixedPoint), (index2, .fixedPoint)]
					}
				}
				.sorted(by: \.index)
				.map(\.argumentType)
			outputStringThingy = stringInterpolation.chunks.map(OutputStringThingyChunk.init)
			textWithoutArguments = stringInterpolation.chunks
				.compactMap {
					switch $0 {
						case .text(let text): text.trimmingCharacters(in: .whitespacesAndNewlines)
						default: nil
					}
				}
				.filter(\.isNotEmpty)
			let badthingArgumentIndicesFromText = stringInterpolation.chunks.flatMap {
				switch $0 {
					case .text: [Int]()
					case .argument(let index, _): [index]
					case .vector(let index1, let index2): [index1, index2]
				}
			}
			argumentIndicesFromText = badthingArgumentIndicesFromText.indices.map {
				badthingArgumentIndicesFromText.firstIndex(of: $0)!
			}
		}
	}
	
	
	static let knownCommands: [UInt32: CommandDefinition] = [
		1:   "dialogue \(0, .dialogue)",
		// 3: (#)
		//     7025 freezes camera focus (?)
		4:   "possibly wipe some data? \(0, .unknown)", // wipes some stored dialogue answer. resets based on the *order* seen??? but the order of these dont matter - maybe smthn to do with DEP files?
		5:   "possibly write some data? \(0, .unknown)",
		//     0xa00001d makes it possible to save
		//     0x50000cf activates wendy's dialogue and skips the hotel manager's first dialogue (softlock)
		//     0x5002d21 makes the samurai unable to battle
//		6: (0x#######)
		7:   "spawn \(0, .character) in \(1, .map) at \(2, 3, .vector) facing \(4, .degrees)",
//		8: (#, #)
		9:   "ambiguous spawn/move/teleport \(0, .character) \(1, .unknown) \(2, .unknown)",
		10:  "teleport \(0, .character) to \(1, .character)",
		14:  "despawn \(0, .character)",
		// 16: (#, #)
		20:  "fade out \(0, .frames)",
		21:  "fade in \(0, .frames)",
		22:  "fade out to white \(0, .frames)",
		23:  "fade in from white \(0, .frames)",
		// 26: (#)
		// 27: (#) 44 makes the hotel person intercept you (which occurs in e0044) but doenst seem to just activate an episode
		32:  "unowned dialogue \(0, .dialogue)",
		33:  "dialogue \(0, .dialogue) with choice \(1, .dialogue)",
		34:  "turn \(0, .character) to \(1, .degrees)",
		35:  "turn1 \(0, .character) to \(1, .degrees) over \(2, .frames), unknown: \(3, .unknown)",
		36:  "turn \(0, .character) towards \(1, .character) over \(2, .frames), unknown: \(3, .unknown)",
		37:  "turn2 \(0, .character) to \(1, .degrees) over \(2, .frames), unknown: \(3, .unknown)",
		38:  "turn \(0, .character) towards \(1, .character) over \(3, .frames), unknowns: \(2, .unknown) \(4, .unknown)",
		39:  "move \(0, .character) to \(1, .character) over \(2, .frames), unknown: \(3, .unknown)",
		// 41: (character?, #, frames?, #) another move-to?
		43:  "move \(0, .character) to position \(1, 2, .vector) over \(3, .frames), unknown: \(4, .unknown)",
		45:  "move \(0, .character) by \(1, 2, .vector) over \(3, .frames), unknown: \(4, .unknown)",
		// 46: (#, #, #.#, #, #)
		50:  "smoothes out movement or something for \(0, .character)",
		51:  "control \(0, .character)",
		// 52: (#, #)
		56:  "delay \(0, .frames)",
		57:  "battle \(1, .unknown), unknown: \(0, .unknown)", // 1 is battle id
		58:  "clean1 \(1, .fossil), unknown: \(0, .unknown)",
		59:  "clean2 \(1, .fossil), unknown: \(0, .unknown)",
		60:  "clean3 \(1, .fossil), unknown: \(0, .unknown)", // (used in fighter test in e0090)
		61:  "angle camera from \(1, 2, .vector) at distance \(3, .fixedPoint) with fov: \(0, .fixedPoint) over \(4, .frames), unknown: \(5, .unknown)",
		// 62: () camera goes to the wrong place sometimes without it (similar to 50??) (is this accurate ???)
		// 63: ()
		70:  "possibly write some data 2? \(0, .unknown), \(1, .unknown)",
		//     writing to 0x9000007 sets the player's profile pic (0-7 is a-h)
		80:  "make \(0, .character) follow \(1, .character)",
		90:  "set level for level-up animation \(0, .unknown)",
		// 112: (#, #)
		114: "set \(0, .character) body model variant to \(1, .unknown)", // 1 is model variant
		115: "set \(0, .character) head model variant to \(1, .unknown)", // 1 is model variant
		// 116: (#) i think this stops music from playing, not sure if thats the main effect or just a side effect
		117: "start music \(0, .music)",
		// 118: ()
		119: "start music 2 \(0, .music)",
		// 120: ()
		124: "fade music \(0, .frames)",
		125: "play sound \(0, .soundEffect)",
		// 128: (#, #)
		129: "effect \(1, .effect) on \(0, .character)",
		131: "clear effects on \(0, .character)",
		135: "movement \(1, .movement) on \(0, .character)",
		138: "shake screen for \(2, .frames) with intensity: \(0, .unknown), gradual intensity: \(1, .unknown)",
		// 141: (#)
		142: "modify player name",
		143: "set player name",
		144: "dialogue \(0, .dialogue) with choice \(2, .dialogue), unknown: \(1, .unknown)",
		150: "level-up animation",
		153: "fade in image \(0, .image) over \(1, .frames) on bottom screen, unknown: \(2, .unknown)", // TODO: is this actually top?
		154: "fade out image over \(0, .frames), unknown: \(1, .unknown)",
		155: "slide in image \(0, .image) over \(2, .frames), unknowns: \(1, .unknown) \(3, .unknown)",
		157: "fade in image \(0, .image) over \(2, .frames), unknowns: \(1, .unknown) \(3, .unknown)",
		159: "fade in image \(0, .image) over \(1, .frames) on top screen, unknown: \(2, .unknown)", // TODO: is this actually bottom?
		// 160: (#, #)
		// 178: () suppresses "Fighter Area" corner tag?
		191: "revive \(0, .vivosaur)",
		194: "unknown 194: \(0, .character)",
		// 195: (#, #)
		200: "start turning \(0, .character) to follow \(1, .character)",
		201: "stop turning \(0, .character)",
	]
	
	static func checkKnownCommands() {
		var allCommandsWithoutArguments = Set<[String]>()
		
		for command in knownCommands.values {
			guard !allCommandsWithoutArguments.contains(command.textWithoutArguments) else {
				print("\(.red)duplicate command text for \(command.textWithoutArguments) >:(\(.normal)")
				preconditionFailure()
			}
			allCommandsWithoutArguments.insert(command.textWithoutArguments)
		}
	}
	
	enum Command {
		case known(type: UInt32, definition: CommandDefinition, arguments: [Int32])
		case unknown(type: UInt32, arguments: [Int32])
		case comment(String)
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
	init(_ binaryCommand: DEX.Binary.Scene.Command) {
		self = if let definition = DEX.knownCommands[binaryCommand.type] {
			.known(
				type: binaryCommand.type,
				definition: definition,
				arguments: binaryCommand.arguments
			)
		} else {
			.unknown(
				type: binaryCommand.type,
				arguments: binaryCommand.arguments
			)
		}
	}
	
	init(_ text: Substring) throws {
		if text.hasPrefix("// ") {
			self = .comment(String(text.dropFirst(3)))
			return
		} else if text.hasPrefix("//") {
			self = .comment(String(text.dropFirst(2)))
			return
		}
		
		let argumentStartIndices = text
			.indices(of: "<")
			.ranges
			.map(\.lowerBound)
		let argumentEndIndices = text
			.indices(of: ">")
			.ranges
			.map(\.upperBound)
		
		let argumentRanges = zip(argumentStartIndices, argumentEndIndices)
			.map { $0..<$1 }
			.map(RangeSet.init)
			.reduce(into: RangeSet()) { $0.formUnion($1) }
		
		let arguments = argumentRanges.ranges
			.map { text[$0].dropFirst().dropLast() }
			.flatMap {
				if $0.contains(", ") {
					$0.split(separator: ", ")
				} else if $0.contains(",") {
					$0.split(separator: ",")
				} else {
					[$0]
				}
			}
		
		let textWithoutArguments = RangeSet(text.startIndex..<text.endIndex)
			.subtracting(argumentRanges)
			.ranges
			.map { text[$0] }
			.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
			.filter(\.isNotEmpty)
		
		if let (commandType, knownCommand) = DEX.knownCommands.first(where: { $0.value.textWithoutArguments == textWithoutArguments }) {
			
			guard knownCommand.argumentIndicesFromText.count == arguments.count else {
				todo("throw error here")
			}
			
			let reorderedArguments = knownCommand.argumentIndicesFromText.map { arguments[$0] }
			
			self = .known(
				type: commandType,
				definition: knownCommand,
				arguments: zip(reorderedArguments, knownCommand.argumentTypes)
					.map {
						guard let number = $1.parse($0) else {
							todo("throw error here")
						}
						return number
					}
			)
		} else {
			guard text.hasPrefix("unknown") else {
				todo("throw error here")
			}
			
			let parsedArguments = arguments
				.map(DEX.ArgumentType.unknown.parse)
				.map {
					guard let value = $0 else { todo("throw error here") }
					return value
				}
			
			guard let commandType = parsedArguments.first else {
				todo("throw error here")
			}
			
			self = .unknown(
				type: UInt32(commandType),
				arguments: Array(parsedArguments.dropFirst())
			)
		}
	}
	
	var typeAndArguments: (UInt32, [Int32])? {
		switch self {
			case .known(let type, _, let arguments): (type, arguments)
			case .unknown(let type, let arguments): (type, arguments)
			case .comment: nil
		}
	}
	
	func linesOfDialogue() -> [Int32] {
		guard case .known(_, let definition, let arguments) = self else { return [] }
		
		return definition.argumentTypes
			.indices { $0 == .dialogue }
			.ranges
			.map(\.lowerBound)
			.map { arguments[$0] }
	}
}

extension String {
	init(_ command: DEX.Command) {
		self = switch command {
			case .known(_, let definition, let arguments):
				definition.outputStringThingy.reduce(into: "") { partialResult, chunk in
					switch chunk {
						case .text(let text):
							partialResult += text
						case .argument(let index):
							partialResult += "<"
							partialResult += definition.argumentTypes[index].format(arguments[index])
							partialResult += ">"
						case .vector(let index1, let index2):
							partialResult += "<"
							partialResult += definition.argumentTypes[index1].format(arguments[index1])
							partialResult += ", "
							partialResult += definition.argumentTypes[index2].format(arguments[index2])
							partialResult += ">"
					}
				}
			case .unknown(let type, []):
				"unknown <\(type)>"
			case .unknown(let type, let arguments):
				{
					// TODO: make this good
					let formattedArguments = arguments
						.map(DEX.ArgumentType.unknown.format)
						.map { "<\($0)>" }
						.joined(separator: " ")
					
					return "unknown <\(type)>: \(formattedArguments)"
				}()
			case .comment(let string):
				("// " + string)
					.replacingOccurrences(of: "\n", with: "\n// ")
					.replacingOccurrences(of: " \n", with: "\n")
		}
	}
}

extension DEX.ArgumentType {
	func parse(_ text: Substring) -> Int32? {
		switch self {
			case .character:       parseLookupTable(characterNames, text: text) ?? parsePrefix(text)
			case .degrees:         parseSuffix(text)
			case .dialogue:        parsePrefix(text)
			case .effect:          parseLookupTable(effectNames, text: text) ?? parsePrefix(text)
			case .fixedPoint:      parseFixedPoint(text)
			case .fossil:          parseLookupTable(fossilNames, text: text) ?? parsePrefix(text)
			case .frames:          parseSuffix(text)
			case .image:           parsePrefix(text)
			case .map:             parseLookupTable(mapNames, text: text) ?? parsePrefix(text)
			case .movement:        parseLookupTable(movementNames, text: text) ?? parsePrefix(text)
			case .music:           parsePrefix(text)
			case .soundEffect:     parsePrefix(text)
			case .unknown:         parseUnknown(text)
			case .vivosaur:        parseLookupTable(vivosaurNames, text: text) ?? parsePrefix(text)
		}
	}
	
	private func parsePrefix(_ text: Substring) -> Int32? {
		text
			.split(whereSeparator: \.isWhitespace)
			.last
			.flatMap { Int32($0) }
	}
	
	private func parseSuffix(_ text: Substring) -> Int32? {
		text
			.split(whereSeparator: \.isWhitespace)
			.first
			.flatMap { Int32($0) }
	}
	
	private func parseLookupTable(_ table: [Int32: String], text: Substring) -> Int32? {
		table
			.first { $0.value.caseInsensitiveEquals(text) }
			.map(\.key)
	}
	
	private func parseFixedPoint(_ text: Substring) -> Int32? {
		Double(text)
			.map { $0 * Double(1 << 12) }
			.map { Int32($0) }
	}
	
	private func parseUnknown(_ text: Substring) -> Int32? {
		if text.contains("0x") {
			Int32(text.replacingOccurrences(of: "0x", with: ""), radix: 16)
		} else {
			Int32(text)
		}
	}
	
	func format(_ number: Int32) -> String {
		switch self {
			case .character:   "\(characterNames[number] ?? "character \(number)")"
			case .degrees:     "\(number) degrees"
			case .dialogue:    "dialogue \(number)"
			case .effect:      "\(effectNames[number] ?? "effect \(number)")"
			case .fixedPoint:  formatFixedPoint(number)
			case .fossil:      "\(fossilNames[number] ?? "fossil \(number)")"
			case .frames:      "\(number) frames"
			case .image:       "image \(number)"
			case .map:         "\(mapNames[number] ?? "map \(number)")"
			case .movement:    "\(movementNames[number] ?? "movement \(number)")"
			case .music:       "music \(number)"
			case .soundEffect: "sound effect \(number)"
			case .unknown:     formatUnknown(number)
			case .vivosaur:    "\(vivosaurNames[number] ?? "vivosaur \(number)")"
		}
	}
	
	private func formatFixedPoint(_ number: Int32) -> String {
		let doubleApprox = Double(number) / Double(1 << 12)
//		let rescaled = doubleApprox * Double(1 << 12)
//		assert(Int32(rescaled) == number) // floating point should be a superset of 20.12 fixed point
		
		if let exactNumber = Int(exactly: doubleApprox) {
			return String(exactNumber)
		} else {
			return String(doubleApprox)
		}
	}
	
	private func formatUnknown(_ number: Int32) -> String {
		if number.magnitude >= UInt16.max {
			hex(number)
		} else {
			String(number)
		}
	}
}

//extension DEX.Command {
//	init(_ commandBinary: DEX.Binary.Scene.Command) {
//		let args = commandBinary.arguments
//		self = switch commandBinary.type {
//			case 1:  .dialogue(Dialogue(args[0]))
//			case 7:  .spawn(Character(args[0]), Map(args[1]), position: Vector(x: args[2], y: args[3]), Angle(args[4]))
//			case 10: .teleport(Character(args[0]), to: Character(args[1]))
//			case 14: .despawn(Character(args[0]))
//			case 20: .fadeOut(FrameCount(args[0]))
//			case 21: .fadeIn(FrameCount(args[0]))
//			case 32: .unownedDialogue(Dialogue(args[0]))
//			case 34: .turnTo(Character(args[0]), Angle(args[1]))
//			case 35: .turn1To(Character(args[0]), Angle(args[1]), FrameCount(args[2]), Unknown(args[3]))
//			case 36: .turnTowards(Character(args[0]), target: Character(args[1]), FrameCount(args[2]), Unknown(args[3]))
//			case 37: .turn2To(Character(args[0]), Angle(args[1]), FrameCount(args[2]), Unknown(args[3]))
//			case 38: .turnTowards2(Character(args[0]), target: Character(args[1]), Unknown(args[2]), FrameCount(args[3]), Unknown(args[4]))
//			case 39: .move(Character(args[0]), to: Character(args[1]), FrameCount(args[2]), Unknown(args[3]))
//			case 43: .moveTo(Character(args[0]), position: Vector(x: args[1], y: args[2]), FrameCount(args[3]), Unknown(args[4]))
//			case 45: .moveBy(Character(args[0]), relative: Vector(x: args[1], y: args[2]), FrameCount(args[3]), Unknown(args[4]))
//			case 51: .control(Character(args[0]))
//			case 56: .delay(FrameCount(args[0]))
//			case 58: .clean1(Unknown(args[0]), Fossil(args[1]))
//			case 59: .clean2(Unknown(args[0]), Fossil(args[1]))
//			case 61: .angleCamera(fov: FixedPoint(args[0]), rotation: Vector(x: args[1], y: args[2]), targetDistance: FixedPoint(args[3]), FrameCount(args[4]), Unknown(args[5]))
//			case 117: .startMusic(id: Music(args[0]))
//			case 124: .fadeMusic(FrameCount(args[0]))
//			case 125: .playSound(id: SoundEffect(args[0]))
//			case 129: .characterEffect(Character(args[0]), Effect(args[1]))
//			case 131: .clearEffects(Character(args[0]))
//			case 135: .characterMovement(Character(args[0]), Movement(args[1]))
//			case 144: .dialogueChoice(Dialogue(args[0]), Unknown(args[1]), choices: Dialogue(args[2]))
//			case 154: .imageFadeOut(FrameCount(args[0]), Unknown(args[1]))
//			case 155: .imageSlideIn(Image(args[0]), Unknown(args[1]), FrameCount(args[2]), Unknown(args[3]))
//			case 157: .imageFadeIn(Image(args[0]), Unknown(args[1]), FrameCount(args[2]), Unknown(args[3]))
//			case 191: .revive(Vivosaur(args[0]))
//			case 200: .startTurning(Character(args[0]), target: Character(args[1]))
//			case 201: .stopTurning(Character(args[0]))
//			default:  .unknown(type: commandBinary.type, arguments: args.map(Unknown.init))
//		}
//	}
//	
//	var typeAndArguments: (UInt32, [Int32])? {
//		switch self {
//			case .dialogue(let dialogue):
//				(1, [dialogue.value])
//			case .spawn(let character, let unknown, let position, let angle):
//				(7, [character.value, unknown.value, position.x, position.y, angle.value])
//			case .teleport(let source, to: let destination):
//				(10, [source.value, destination.value])
//			case .despawn(let character):
//				(14, [character.value])
//			case .fadeOut(let frames):
//				(20, [frames.value])
//			case .fadeIn(let frames):
//				(21, [frames.value])
//			case .unownedDialogue(let dialogue):
//				(32, [dialogue.value])
//			case .turnTo(let character, let angle):
//				(34, [character.value, angle.value])
//			case .turn1To(let character, let angle, let frames, let unknown):
//				(35, [character.value, angle.value, frames.value, unknown.value])
//			case .turnTowards(let character, let target, let frames, let unknown):
//				(36, [character.value, target.value, frames.value, unknown.value])
//			case .turn2To(let character, let angle, let frames, let unknown):
//				(37, [character.value, angle.value, frames.value, unknown.value])
//			case .turnTowards2(let character, let target, let unknown1, let frames, let unknown2):
//				(38, [character.value, target.value, unknown1.value, frames.value, unknown2.value])
//			case .move(let source, to: let destination, let frames, let unknown):
//				(39, [source.value, destination.value, frames.value, unknown.value])
//			case .moveTo(let character, let position, let frames, let unknown):
//				(43, [character.value, position.x, position.y, frames.value, unknown.value])
//			case .moveBy(let character, let relative, let frames, let unknown):
//				(45, [character.value, relative.x, relative.y, frames.value, unknown.value])
//			case .control(let character):
//				(51, [character.value])
//			case .delay(let frames):
//				(56, [frames.value])
//			case .clean1(let unknown, let fossil):
//				(58, [unknown.value, fossil.value])
//			case .clean2(let unknown, let fossil):
//				(59, [unknown.value, fossil.value])
//			case .angleCamera(let fov, let rotation, let targetDistance, let frames, let unknown):
//				(61, [fov.value, rotation.x, rotation.y, targetDistance.value, frames.value, unknown.value])
//			case .startMusic(let id):
//				(117, [id.value])
//			case .fadeMusic(let frames):
//				(124, [frames.value])
//			case .playSound(let soundEffect):
//				(125, [soundEffect.value])
//			case .characterEffect(let character, let effect):
//				(129, [character.value, effect.value])
//			case .clearEffects(let character):
//				(131, [character.value])
//			case .characterMovement(let character, let movement):
//				(135, [character.value, movement.value])
//			case .dialogueChoice(let dialogue, let unknown, let choices):
//				(144, [dialogue.value, unknown.value, choices.value])
//			case .imageFadeOut(let frames, let unknown):
//				(154, [frames.value, unknown.value])
//			case .imageSlideIn(let image, let unknown1, let frames, let unknown2):
//				(155, [image.value, unknown1.value, frames.value, unknown2.value])
//			case .imageFadeIn(let image, let unknown1, let frames, let unknown2):
//				(157, [image.value, unknown1.value, frames.value, unknown2.value])
//			case .revive(let vivosaur):
//				(191, [vivosaur.value])
//			case .startTurning(let character, let target):
//				(200, [character.value, target.value])
//			case .stopTurning(let character):
//				(201, [character.value])
//			case .unknown(let type, let arguments):
//				(type, arguments.map(\.value))
//			case .comment: nil
//		}
//	}
//	
//	init(_ text: Substring) throws {
//		let (command, arguments) = try parse(command: text)
//		
//		if let expectedArgumentCount = command.argumentCount {
//			guard arguments.count == expectedArgumentCount else {
//				throw InvalidCommand.invalidNumberOfArguments(
//					expected: expectedArgumentCount,
//					got: arguments.count,
//					command: text
//				)
//			}
//		} else if case .unknown = command {
//			guard arguments.count > 0 else {
//				throw InvalidCommand.invalidNumberOfArguments(
//					expected: 1,
//					got: arguments.count,
//					command: text
//				)
//			}
//		}
//		
//		func invalidArgument(_ argumentNumber: Int) -> some Error {
//			InvalidCommand.invalidArgument(argument: arguments[argumentNumber], command: text)
//		}
//		
//		self = switch command {
//			case .dialogue: .dialogue(
//				try Dialogue(arguments[0]).orElseThrow(invalidArgument(0))
//			)
//			case .spawn: .spawn(
//				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
//				try Map(arguments[1]).orElseThrow(invalidArgument(2)),
//				position: try Vector(arguments[2]).orElseThrow(invalidArgument(1)),
//				try Angle(arguments[3]).orElseThrow(invalidArgument(3))
//			)
//			case .teleport: .teleport(
//				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
//				to: try Character(arguments[1]).orElseThrow(invalidArgument(1))
//			)
//			case .despawn: .despawn(
//				try Character(arguments[0]).orElseThrow(invalidArgument(0))
//			)
//			case .fadeOut: .fadeOut(
//				try FrameCount(arguments[0]).orElseThrow(invalidArgument(0))
//			)
//			case .fadeIn: .fadeIn(
//				try FrameCount(arguments[0]).orElseThrow(invalidArgument(0))
//			)
//			case .unownedDialogue: .unownedDialogue(
//				try Dialogue(arguments[0]).orElseThrow(invalidArgument(0))
//			)
//			case .turnTo: .turnTo(
//				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
//				try Angle(arguments[1]).orElseThrow(invalidArgument(1))
//			)
//			case .turn1To: .turn1To(
//				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
//				try Angle(arguments[1]).orElseThrow(invalidArgument(1)),
//				try FrameCount(arguments[2]).orElseThrow(invalidArgument(2)),
//				try Unknown(arguments[3]).orElseThrow(invalidArgument(3))
//			)
//			case .turnTowards: .turnTowards(
//				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
//				target: try Character(arguments[1]).orElseThrow(invalidArgument(1)),
//				try FrameCount(arguments[2]).orElseThrow(invalidArgument(2)),
//				try Unknown(arguments[3]).orElseThrow(invalidArgument(3))
//			)
//			case .turn2To: .turn2To(
//				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
//				try Angle(arguments[1]).orElseThrow(invalidArgument(1)),
//				try FrameCount(arguments[2]).orElseThrow(invalidArgument(2)),
//				try Unknown(arguments[3]).orElseThrow(invalidArgument(3))
//			)
//			case .turnTowards2: .turnTowards2(
//				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
//				target: try Character(arguments[1]).orElseThrow(invalidArgument(1)),
//				try Unknown(arguments[3]).orElseThrow(invalidArgument(3)),
//				try FrameCount(arguments[2]).orElseThrow(invalidArgument(2)),
//				try Unknown(arguments[4]).orElseThrow(invalidArgument(4))
//			)
//			case .move: .move(
//				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
//				to: try Character(arguments[1]).orElseThrow(invalidArgument(1)),
//				try FrameCount(arguments[2]).orElseThrow(invalidArgument(2)),
//				try Unknown(arguments[3]).orElseThrow(invalidArgument(3))
//			)
//			case .moveTo: .moveTo(
//				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
//				position: try Vector(arguments[1]).orElseThrow(invalidArgument(1)),
//				try FrameCount(arguments[2]).orElseThrow(invalidArgument(2)),
//				try Unknown(arguments[3]).orElseThrow(invalidArgument(3))
//			)
//			case .moveBy: .moveBy(
//				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
//				relative: try Vector(arguments[1]).orElseThrow(invalidArgument(1)),
//				try FrameCount(arguments[2]).orElseThrow(invalidArgument(2)),
//				try Unknown(arguments[3]).orElseThrow(invalidArgument(3))
//			)
//			case .control: .control(
//				try Character(arguments[0]).orElseThrow(invalidArgument(0))
//			)
//			case .delay: .delay(
//				try FrameCount(arguments[0]).orElseThrow(invalidArgument(0))
//			)
//			case .clean1: .clean1(
//				try Unknown(arguments[1]).orElseThrow(invalidArgument(1)),
//				try Fossil(arguments[0]).orElseThrow(invalidArgument(0))
//			)
//			case .clean2: .clean2(
//				try Unknown(arguments[1]).orElseThrow(invalidArgument(1)),
//				try Fossil(arguments[0]).orElseThrow(invalidArgument(0))
//			)
//			case .angleCamera: .angleCamera(
//				fov: try FixedPoint(arguments[2]).orElseThrow(invalidArgument(2)),
//				rotation: try Vector(arguments[0]).orElseThrow(invalidArgument(0)),
//				targetDistance: try FixedPoint(arguments[1]).orElseThrow(invalidArgument(1)),
//				try FrameCount(arguments[3]).orElseThrow(invalidArgument(3)),
//				try Unknown(arguments[4]).orElseThrow(invalidArgument(4))
//			)
//			case .startMusic: .startMusic(
//				id: try Music(arguments[0]).orElseThrow(invalidArgument(0))
//			)
//			case .fadeMusic: .fadeMusic(
//				try FrameCount(arguments[0]).orElseThrow(invalidArgument(0))
//			)
//			case .playSound: .playSound(
//				id: try SoundEffect(arguments[0]).orElseThrow(invalidArgument(0))
//			)
//			case .characterEffect: .characterEffect(
//				try Character(arguments[1]).orElseThrow(invalidArgument(1)),
//				try Effect(arguments[0]).orElseThrow(invalidArgument(0))
//			)
//			case .clearEffects: .clearEffects(
//				try Character(arguments[0]).orElseThrow(invalidArgument(0))
//			)
//			case .characterMovement: .characterMovement(
//				try Character(arguments[1]).orElseThrow(invalidArgument(1)),
//				try Movement(arguments[0]).orElseThrow(invalidArgument(0))
//			)
//			case .dialogueChoice: .dialogueChoice(
//				try Dialogue(arguments[0]).orElseThrow(invalidArgument(0)),
//				try Unknown(arguments[2]).orElseThrow(invalidArgument(2)),
//				choices: try Dialogue(arguments[1]).orElseThrow(invalidArgument(1))
//			)
//			case .imageFadeOut: .imageFadeOut(
//				try FrameCount(arguments[0]).orElseThrow(invalidArgument(0)),
//				try Unknown(arguments[1]).orElseThrow(invalidArgument(1))
//			)
//			case .imageSlideIn: .imageSlideIn(
//				try Image(arguments[0]).orElseThrow(invalidArgument(0)),
//				try Unknown(arguments[2]).orElseThrow(invalidArgument(2)),
//				try FrameCount(arguments[1]).orElseThrow(invalidArgument(1)),
//				try Unknown(arguments[3]).orElseThrow(invalidArgument(3))
//			)
//			case .imageFadeIn: .imageFadeIn(
//				try Image(arguments[0]).orElseThrow(invalidArgument(0)),
//				try Unknown(arguments[2]).orElseThrow(invalidArgument(2)),
//				try FrameCount(arguments[1]).orElseThrow(invalidArgument(1)),
//				try Unknown(arguments[3]).orElseThrow(invalidArgument(3))
//			)
//			case .revive: .revive(
//				try Vivosaur(arguments[0]).orElseThrow(invalidArgument(0))
//			)
//			case .startTurning: .startTurning(
//				try Character(arguments[0]).orElseThrow(invalidArgument(0)),
//				target: try Character(arguments[1]).orElseThrow(invalidArgument(1))
//			)
//			case .stopTurning: .stopTurning(
//				try Character(arguments[0]).orElseThrow(invalidArgument(0))
//			)
//			case .unknown: .unknown(
//				type: try UInt32(arguments[0]).orElseThrow(invalidArgument(0)),
//				arguments: try arguments
//					.enumerated()
//					.dropFirst()
//					.map { try Unknown($0.element).orElseThrow(invalidArgument($0.offset)) }
//			)
//			case .comment: .comment(String(text.dropFirst(3)))
//		}
//	}
//	
//	var isNotComment: Bool {
//		switch self {
//			case .comment: false
//			default: true
//		}
//	}
//}

//extension String {
//	init(_ command: DEX.Command) {
//		self = switch command {
//			case .dialogue(let dialogue):
//				"dialogue \(dialogue)"
//			case .spawn(let character, let map, let position, let angle):
//				"spawn \(character) in \(map) at \(position) facing \(angle)"
//			case .teleport(let source, to: let destination):
//				"teleport \(source) to \(destination)"
//			case .despawn(let character):
//				"despawn \(character)"
//			case .fadeOut(frameCount: let frameCount):
//				"fade out \(frameCount)"
//			case .fadeIn(frameCount: let frameCount):
//				"fade in \(frameCount)"
//			case .unownedDialogue(let dialogue):
//				"unowned dialogue \(dialogue)"
//			case .turnTo(let character, let angle):
//				"turn \(character) to \(angle)"
//			case .turn1To(let character, let angle, let frameCount, let unknown):
//				"turn1 \(character) to \(angle) over \(frameCount), unknown: \(unknown)"
//			case .turnTowards(let character, target: let target, let frameCount, let unknown):
//				"turn \(character) towards \(target) over \(frameCount), unknown: \(unknown)"
//			case .turn2To(let character, let angle, let frameCount, let unknown):
//				"turn2 \(character) to \(angle) over \(frameCount), unknown: \(unknown)"
//			case .turnTowards2(let character, target: let target, let unknown1, let frameCount, let unknown2):
//				"turn \(character) towards \(target) over \(frameCount), unknowns: \(unknown1) \(unknown2)"
//			case .move(let source, to: let destination, let frameCount, let unknown):
//				"move \(source) to \(destination) over \(frameCount), unknown: \(unknown)"
//			case .moveTo(let character, let position, let frameCount, let unknown):
//				"move \(character) to \(position) over \(frameCount), unknown: \(unknown)"
//			case .moveBy(let character, relative: let relative, let frameCount, let unknown):
//				"move \(character) by \(relative) over \(frameCount), unknown: \(unknown)"
//			case .control(let character):
//				"control \(character)"
//			case .delay(frameCount: let frameCount):
//				"delay \(frameCount)"
//			case .clean1(let unknown, let fossil):
//				"clean1 \(fossil), unknown: \(unknown)"
//			case .clean2(let unknown, let fossil):
//				"clean2 \(fossil), unknown: \(unknown)"
//			case .angleCamera(fov: let fov, rotation: let rotation, targetDistance: let targetDistance, let frameCount, let unknown):
//				"angle camera from \(rotation) at distance \(targetDistance) with fov: \(fov) over \(frameCount), unknown: \(unknown)"
//			case .startMusic(id: let id):
//				"start music \(id)"
//			case .fadeMusic(frameCount: let frameCount):
//				"fade music \(frameCount)"
//			case .playSound(id: let id):
//				"play sound \(id)"
//			case .characterEffect(let character, let effect):
//				"effect \(effect) on \(character)"
//			case .clearEffects(let character):
//				"clear effects on \(character)"
//			case .characterMovement(let character, let movement):
//				"movement \(movement) on \(character)"
//			case .dialogueChoice(let dialogue, let unknown, choices: let choices):
//				"dialogue \(dialogue) with choice \(choices), unknown: \(unknown)"
//			case .imageFadeOut(let frameCount, let unknown):
//				"fade out image over \(frameCount), unknown: \(unknown)"
//			case .imageSlideIn(let image, let unknown1, let frameCount, let unknown2):
//				"slide in image \(image) over \(frameCount), unknowns: \(unknown1) \(unknown2)"
//			case .imageFadeIn(let image, let unknown1, let frameCount, let unknown2):
//				"fade in image \(image) over \(frameCount), unknowns: \(unknown1) \(unknown2)"
//			case .revive(let vivosaur):
//				"revive \(vivosaur)"
//			case .startTurning(let character, target: let target):
//				"start turning \(character) to follow \(target)"
//			case .stopTurning(let character):
//				"stop turning \(character)"
//			case .unknown(type: let type, arguments: []):
//				"unknown <\(type)>"
//			case .unknown(type: let type, arguments: let arguments):
//				"unknown <\(type)>: \(arguments.map(\.description).joined(separator: " "))"
//			case .comment(""):
//				"//"
//			case .comment(let text) where text.starts(with: "\n"):
//				"//\(text)"
//			case .comment(let text):
//				"// \(text)"
//		}
//	}
//}

//extension DEX.Command.Argument: CustomStringConvertible {
//	init?(_ text: Substring) {
//		guard let value = Unit.parse(text) else { return nil }
//		self.value = value
//	}
//	
//	var description: String {
//		"<\(Unit.format(value))>"
//	}
//}

//extension DEX.Command.Vector: CustomStringConvertible {
//	init?(_ text: Substring) {
//		let coords = text.split(separator: ", ")
//		guard coords.count == 2,
//			  let x = FixedPointUnit.parse(coords[0]),
//			  let y = FixedPointUnit.parse(coords[1]) else { return nil }
//		
//		self.x = x
//		self.y = y
//	}
//	
//	var description: String {
//		"<\(FixedPointUnit.format(x)), \(FixedPointUnit.format(y))>"
//	}
//}

//enum CommandType {
//	case dialogue, spawn, teleport, despawn, fadeOut, fadeIn, unownedDialogue, turnTo, turn1To, turnTowards, turn2To, turnTowards2, move, moveTo, moveBy, control, delay, clean1, clean2, angleCamera, startMusic, fadeMusic, playSound, characterEffect, clearEffects, characterMovement, dialogueChoice, imageFadeOut, imageSlideIn, imageFadeIn, revive, startTurning, stopTurning, unknown, comment
//	
//	init?(_ command: Substring) {
//		let firstSpace = command.firstIndex(where: \.isWhitespace) ?? command.endIndex
//		let firstWord = command[..<firstSpace]
//		
//		let possiblySelf: Self? = switch firstWord {
//			case "dialogue":
//				if command.contains("choice") {
//					.dialogueChoice
//				} else {
//					.dialogue
//				}
//			case "spawn": .spawn
//			case "teleport": .teleport
//			case "despawn": .despawn
//			case "fade":
//				if command.contains("image") {
//					if command.contains("in") {
//						.imageFadeIn
//					} else {
//						.imageFadeOut
//					}
//				} else if command.contains("music") {
//					.fadeMusic
//				} else {
//					if command.contains("in") {
//						.fadeIn
//					} else {
//						.fadeOut
//					}
//				}
//			case "unowned": .unownedDialogue
//			case "turn":
//				if command.contains("unknowns") {
//					.turnTowards2
//				} else if command.contains("unknown") {
//					.turnTowards
//				} else {
//					.turnTo
//				}
//			case "turn1": .turn1To
//			case "turn2": .turn2To
//			case "move":
//				if command.contains("to") {
//					if command.count(where: { $0 == "," }) > 1 {
//						.moveTo
//					} else {
//						.move
//					}
//				} else {
//					.moveBy
//				}
//			case "control": .control
//			case "delay": .delay
//			case "clean1": .clean1
//			case "clean2": .clean2
//			case "angle": .angleCamera
//			case "start":
//				if command.contains("music") {
//					.startMusic
//				} else {
//					.startTurning
//				}
//			case "play": .playSound
//			case "effect": .characterEffect
//			case "clear": .clearEffects
//			case "movement": .characterMovement
//			case "slide": .imageSlideIn
//			case "revive": .revive
//			case "stop": .stopTurning
//			case "unknown": .unknown
//			case "//": .comment
//			default: nil
//		}
//		
//		guard let possiblySelf else { return nil }
//		self = possiblySelf
//	}
//	
//	var argumentCount: Int? {
//		switch self {
//			case .dialogue, .despawn, .fadeOut, .fadeIn, .unownedDialogue, .control, .delay, .startMusic, .fadeMusic, .playSound, .clearEffects, .revive, .stopTurning: 1
//			case .teleport, .turnTo, .clean1, .clean2, .characterEffect, .characterMovement, .imageFadeOut, .startTurning: 2
//			case .dialogueChoice: 3
//			case .move, .moveTo, .moveBy, .spawn, .turn1To, .turnTowards, .turn2To, .imageSlideIn, .imageFadeIn: 4
//			case .turnTowards2, .angleCamera: 5
//			case .unknown, .comment: nil
//		}
//	}
//}

//fileprivate func parse(command commandText: Substring) throws -> (CommandType, [Substring]) {
//	guard let command = CommandType(commandText) else {
//		throw DEX.Command.InvalidCommand.invalidCommand(commandText)
//	}
//	
//	let argumentStartIndices = commandText
//		.indices(of: "<")
//		.ranges
//		.map(\.upperBound)
//	let argumentEndIndices = commandText
//		.indices(of: ">")
//		.ranges
//		.map(\.lowerBound)
//	
//	let arguments = zip(argumentStartIndices, argumentEndIndices)
//		.map { startIndex, endIndex in
//			commandText[startIndex..<endIndex]
//		}
//	
//	return (command, arguments)
//}
