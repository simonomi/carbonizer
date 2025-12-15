import BinaryParser
import Foundation

enum DEX {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "DEX"
		var eventCount: UInt32
		var eventOffsetsOffset: UInt32 = 0xC
		@Count(givenBy: \Self.eventCount)
		@Offset(givenBy: \Self.eventOffsetsOffset)
		var eventOffsets: [UInt32]
		@Offsets(givenBy: \Self.eventOffsets)
		var events: [Event]
		
		@BinaryConvertible
		struct Event {
			var numberOfCommands: UInt32
			var commandOffsetsOffset: UInt32 = 0x8
			@Count(givenBy: \Self.numberOfCommands)
			@Offset(givenBy: \Self.commandOffsetsOffset)
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
	
	struct Unpacked {
		var commands: [[Command]]
		
		enum ArgumentType {
			case boolean, entity, degrees, dialogue, effect, fixedPoint, flag, fossil, frames, image, integer, map, movement, music, soundEffect, unknown, vivosaur
			// notes on flags:
			// - two numbers, a u16 and u8 (is the u8 actually a u16?)
			// - u16 is lower bits, u8 is upper (>> 24)
			// - i list them u16 u8, should i swap that?
			// - 2nd number seems to be a type maybe?
			// - all 2nd numbers: 0, 2, 5, 6, 7, 8, 9, 10
			//   - 0: used for flag4s, dialogue with choice (both kinds) result
			//     dep: never (read with 8? maybe 9?)
			//   - 2: never
			//     dep: has played, has not played (events)
			//   - 3: never
			//     dep: has played, has not played (events)
			//   - 5: used for flag5 and flag6
			//     dep: 19 20 21 22 (boolean)
			//   - 6: used for flag5 and flag6
			//     dep: 19 20 21 22 (boolean)
			//   - 7: used for flag5
			//     dep: 20 21 (boolean)
			//     MASKS!!!!!!!!!!
			//   - 8: flag70
			//     dep: 7 8 9 10 11 13 14 15 17 18 19 21 (aka 7-11 13-15 17-19 21) (numerical AND boolean)
			//   - 9: flag70
			//     dep: 7 8 9 10 11 13 14 15 16 17 18 (aka 7-11 13-18) (aka numerical comparisons)
			//     player stats/settings (money, mask, dp, sonar upgrades)
			//   - 10: flag5 flag6
			//     dep: flag19 flag21 <>   SDf
			// ---
			// <59 0> is used to save a dialogue choice, read at 8
			// <12202 0> is used for battle results (read with 5)
			// <274 0/8> is used for dialogue
			// ---
			// <211 5> is set to true when wendy says "welcome to the fossil center"
			// - "told to check in"?
			// - "visited fossil center"?
			// - "opening cutscene played"?
			// <207 5> - "checked in at hotel" (when dropped off in room, not when leaving)
			// <212 5> - set during diggins' cleaning tutorial
			// <223 5> - set when battling travers (set to false if you lose)
			// <260 5> - is asking diggins questions (end of cleaning tut or if u come back)
			// --- 6 is keyitems
			// <218-223 6> may have smthn to do with case size
			// <248-253 6> are idol fragments
			// --- 7 is masks
			// <15 7> being set with flag5 gives digadig mask
			// <16 7> being set with flag5 gives chieftain mask
			// <2 7> being set with flag5 gives hip-shaker mask
			// ---
			// <56 8> is probably chapter number
			// <59 8> might be mask shop result? or maybe previous mask?
			// <59 8> is used to read a dialogue choice (temp variable?)
			// <62 8> number of sonar upgrades left
			// <67 8> number of cleaning upgrades left
			// <68 8> number of case upgrades (1:8, 2:16, 3:24, 4:32, 5:48)
			// --- 9 seems to be player stats
			// <2 9> == 1 means your case is size 8
			// <3 9> is money
			// <4 9> is current mask
			// <7 9> is player pfp (hunter variant??)
			// <9 9> may be number of fossil rocks
			// <19 9> is donation points
			// <26 9> may be number of oasis seeds? no probably not
			// <30 9> is sonar monitor upgrades (2 is 800 G, 3 is 3500 G)
			// <31 9> is sonar fossil chips (2 is 10000 G, 3 is 35000 G)
			// <32 9> is sonar fossil filters (2 is 5000 G, 3 is 8000 G)
		}
		
		struct CommandDefinition {
			// used to parse each argument
			var argumentTypes: [ArgumentType]
			// used to generate output string
			var outputStringThingy: [OutputStringThingyChunk]
			// used to match command type
			var textWithoutArguments: [String]
			// used to reorder arguments when reading from string
			var argumentIndicesFromText: [Int] // this is the mapping of the binary order to text order TODO: rename
		}
		
		// any time these are updated, also update fftechwiki
		static let ff1Commands: [UInt32: CommandDefinition] = [
			1:   "dialogue \(0, .dialogue)",
			2:   "centered dialogue \(0, .dialogue)",
			3:   "unknown 3 \(0, .flag)", // (flag is an event)
			//    marks an event as having played/not played?
			//     7025 freezes camera focus (?)
			4:   "clear flag \(0, .flag)",
			// wipes some stored dialogue answer. argument is the index in DEP
			// possibly dep too but the 2nd number is always 0
			// mark dialogue as not played!!!!!!!!!! (and possibly other things)
			// clear?? flag? but how is it different than flag 6?
			5:   "set flag \(0, .flag) to true",
			//     0xa00001d <29 10> makes it possible to save
			//     0x50000cf <207 5> activates wendy's dialogue and skips the hotel manager's first dialogue (softlock)
			//     0x5002d21 <11553 5> makes the samurai unable to battle
			//     activates DEP's unknown 19
			//     set true?
			//     memory types 5, 6, 7, 10
			6:   "set flag \(0, .flag) to false",
			//     0x500010f <271 5> is set with memory 6 when resetting name, and memory 5 when resetting vivosaur
			//     set false?
			//     memory types 5, 6, 10
			7:   "spawn \(0, .entity) in \(1, .map) at \(2, 3, .vector) facing \(4, .degrees)",
			// 8:   (entity, #)
			// spawn slot thing?
			// TODO: 8: "spawn \(0, .entity) in slot \(1, .integer)",?
			9:   "spawn \(0, .entity) in slot \(1, .integer) facing \(2, .degrees)",
			10:  "teleport \(0, .entity) to \(1, .entity)",
			14:  "despawn \(0, .entity)",
			// 16: (#, #)
			20:  "fade out \(0, .frames)",
			21:  "fade in \(0, .frames)",
			22:  "fade out to white \(0, .frames)",
			23:  "fade in from white \(0, .frames)",
			// 26: (#)
			// 27: (#) 44 makes the hotel person intercept you (which occurs in e0044) but doenst seem to just activate an episode
			32:  "unowned dialogue \(0, .dialogue)",
			33:  "dialogue with choice \(1, .dialogue), storing result at \(0, .flag)",
			34:  "turn \(0, .entity) to \(1, .degrees)",
			35:  "turn1 \(0, .entity) to \(1, .degrees) over \(2, .frames), unknown: \(3, .unknown)",
			36:  "turn \(0, .entity) towards \(1, .entity) over \(2, .frames), unknown: \(3, .unknown)",
			37:  "turn2 \(0, .entity) to \(1, .degrees) over \(2, .frames), unknown: \(3, .unknown)",
			38:  "turn \(0, .entity) towards \(1, .entity) over \(3, .frames), unknowns: \(2, .unknown) \(4, .unknown)",
			39:  "move \(0, .entity) to \(1, .entity) over \(2, .frames), unknown: \(3, .unknown)",
			40:  "unknown 40: \(0, .entity), \(1, .entity), \(2, .frames), \(3, .unknown)",
			// ?
			// probably another move
			// last # is smoothing
			41:  "unknown 41: \(0, .entity), \(1, .unknown), \(2, .frames), \(3, .unknown)",
			// another move-to?
			// last # is probably smoothing
			43:  "move \(0, .entity) to position \(1, 2, .vector) over \(3, .frames), unknown: \(4, .unknown)",
			44:  "unknown 44: \(0, .entity) \(1, 2, .vector) \(3, .frames) \(4, .unknown)",
			45:  "move \(0, .entity) by \(1, 2, .vector) over \(3, .frames), unknown: \(4, .unknown)",
			// 46: (#, #, fp, #, #)
			47:  "turn \(0, .entity) by \(1, .degrees), then move by \(2, .fixedPoint) over \(3, .frames). unknown: \(4, .unknown)",
			// 4 seems to add a delay before they actually start moving? like theyre slow and then fast
			// its basically a smoothing (ease in/out) effect
			50:  "smoothes out movement or something for \(0, .entity)",
			51:  "control \(0, .entity)",
			// 52: (#, #)
			55:  "dialogue \(2, .dialogue) with choice, storing result at \(1, .flag), unknown: \(0, .unknown)",
			56:  "delay \(0, .frames)",
			57:  "battle \(1, .integer), storing result at \(0, .flag)", // TODO: create battle id type?
			58:  "clean1 \(1, .fossil), unknown: \(0, .unknown)",
			59:  "clean2 \(1, .fossil), unknown: \(0, .unknown)",
			// unknown is which flag to save the result in (type 5)
			// "storing result at"
			60:  "clean3 \(1, .fossil), unknown: \(0, .unknown)", // (used in fighter test in e0090)
			61:  "angle camera from \(1, 2, .vector) at distance \(3, .fixedPoint) with fov: \(0, .fixedPoint) over \(4, .frames), unknown: \(5, .unknown)",
			62:  "unknown 62",
			//    often after diologue choices
			//    often after battles
			//    after sue asks where to go, removing memory but keeping 62 makes camera low, but without 62 camera resets properly
			//    return? is it only used when dep event's unknown2 (i bet yes)
			63:  "unknown 63",
			70:  "set flag \(0, .flag) to \(1, .integer)",
			71:  "add \(1, .integer) to flag \(0, .flag)",
			72:  "subtract \(1, .integer) from flag \(0, .flag)",
			75:  "set flag \(0, .flag) to flag \(1, .flag)",
			80:  "make \(0, .entity) follow \(1, .entity)",
			82:  "make \(0, .entity) wander randomly, waiting between \(1, .frames) and \(2, .frames), walking speed \(3, .fixedPoint), distance up to \(4, .fixedPoint)",
			86:  "make \(0, .entity) chase player, detection range \(1, .fixedPoint), run distance \(2, .fixedPoint), chasing speed \(3, .fixedPoint), returning speed \(4, .fixedPoint), cooldown \(5, .frames)",
			90:  "set fighter level to \(0, .integer)",
			91:  "set case page count to \(0, .integer)",
			97:  "set \(0, .vivosaur) fossil scores to \(1, .integer) \(2, .integer) \(3, .integer) \(4, .integer)",
			99:  "disable dino medals",
			100: "enable dino medals",
			102: "open fossil rock buying shop",
			103: "open fossil rock selling shop",
			104: "open mask buying shop",
//			105: (#)  // does... nothing? arg 0 and 3+ crashes
			106: "open mask wearing shop",
			107: "give \(0, .fossil), dark: \(1, .boolean), red: \(2, .boolean)",
			108: "give \(0, .fossil) without message, dark: \(1, .boolean), red: \(2, .boolean)",
			112: "play animation \(1, .integer) on \(0, .entity)",
			113: "loop animation \(1, .integer) on \(0, .entity)",
			114: "set \(0, .entity) body model variant to \(1, .integer)",
			115: "set \(0, .entity) head model variant to \(1, .integer)",
			// 116: (#) this has some effect on music, but the number isnt a music id
			117: "start music \(0, .music)",
			118: "start ambient music",
			119: "start music 2 \(0, .music)",
			// 120: ()
			// always(?) used near a fade out/fade in, usually after a unknown116
			124: "fade music \(0, .frames)",
			125: "play sound \(0, .soundEffect)",
			128: "unknown 128, unknowns: \(0, .unknown) \(1, .frames)",
			129: "effect \(1, .effect) on \(0, .entity)",
			131: "clear effects on \(0, .entity)",
			134: "wait for a-press",
			135: "movement \(1, .movement) on \(0, .entity)",
			136: "unknown 136: \(0, .entity) \(1, .unknown)",
			//   1 24 - makes hunter blush
			137: "unknown 137: \(0, .entity)",
			138: "shake screen for \(2, .frames) with intensity: \(0, .integer), gradual intensity: \(1, .integer)",
			// 141: (#)
			142: "modify player name", // has back button
			143: "set player name",
			144: "dialogue \(0, .dialogue) with choice \(2, .dialogue), storing result at \(1, .flag)",
			145: "dialogue \(0, .dialogue) with choice \(2, .dialogue), storing result at \(1, .flag), unknown: \(3, .unknown)",
			150: "level-up animation",
			153: "fade in image \(0, .image) over \(1, .frames) on bottom screen, unknown: \(2, .unknown)", // TODO: is this actually top?
			154: "fade out image over \(0, .frames), unknown: \(1, .unknown)",
			155: "slide in image \(0, .image) over \(2, .frames), unknowns: \(1, .unknown) \(3, .unknown)",
			156: "slide out image over \(1, .frames), unknowns: \(0, .unknown) \(2, .unknown)",
			157: "fade in image \(0, .image) over \(2, .frames), unknowns: \(1, .fixedPoint) \(3, .unknown)",
			159: "fade in image \(0, .image) over \(1, .frames) on top screen, unknown: \(2, .unknown)", // TODO: is this actually bottom?
			// 160: (#, #)
			// 161: (#, entity??, frames??, smoothing??)
			// - makes an image appear on the top screen
			// 162: (#, #, #)
			// - slides the top screen image down and away
			// 178: () suppresses "Fighter Area" corner tag?
			//     used in e0302 before a fossil battle
			// 179: (#)
			180: "disable sonar over \(0, .frames)",
//			181: "enable sonar over \(0, .frames)", // TODO: the argument is optional
			190: "access fossil museum",
			191: "show revival screen for \(0, .vivosaur)",
			194: "unknown 194: \(0, .entity)",
			// 195: (#, #)
			200: "start turning \(0, .entity) to follow \(1, .entity)",
			201: "stop turning \(0, .entity)",
			202: "show G banner",
			203: "hide G banner",
			206: "set \(0, .vivosaur) battle points to \(1, .integer)"
			
			// all the unknown commands as of rn 3 8 11 12 16 17 18 19 24 25 26 27 40 41 42 46 47 48 52 53 55 62 63 76 77 81 83 84 85 87 88 89 91 92 93 95 96 98 99 100 105 110 111 113 116 118 120 121 126 127 128 134 137 141 145 147 148 149 152 156 158 160 161 162 165 166 171 178 179 180 181 182 183 184 185 186 187 188 190 192 193 195 196 197 199 202 203 204 205
		]
		
		// any time these are updated, also update fftechwiki
		static let ffcCommands: [UInt32: CommandDefinition] = [
			71:  "dialogue \(0, .dialogue)",
			107: "unowned dialogue \(0, .dialogue)",
		]
		
		static func knownCommands(for configuration: Configuration) -> [UInt32: CommandDefinition] {
			switch configuration.game {
				case .ff1: ff1Commands
				case .ffc: ffcCommands
			}
		}
		
		enum Command {
			case known(type: UInt32, definition: CommandDefinition, arguments: [Int32])
			case unknown(type: UInt32, arguments: [Int32])
			case comment(String)
			
			enum ParseError: Error {
				case failedToParse(Substring, in: Substring)
				case incorrectArgumentCount(command: Substring, actual: Int, expected: Int)
				case unknownCommand(Substring)
				case mismatchedAngleBrackets(requirement: Substring)
			}
		}
	}
}

// MARK: packed
extension DEX.Packed: ProprietaryFileData {
	static let fileExtension = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) throws -> DEX.Unpacked {
		try DEX.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: DEX.Unpacked, configuration: Configuration) {
		eventCount = UInt32(unpacked.commands.count)
		
		events = unpacked.commands.map(Event.init)
		
		eventOffsets = makeOffsets(
			start: eventOffsetsOffset + eventCount * 4,
			sizes: events.map { $0.size() }
		)
	}
}

extension DEX.Packed.Event {
	init(_ commands: [DEX.Unpacked.Command]) {
		self.commands = commands.compactMap(Command.init)
		
		numberOfCommands = UInt32(self.commands.count)
		
		commandOffsets = makeOffsets(
			start: commandOffsetsOffset + numberOfCommands * 4,
			sizes: self.commands.map(\.size)
		)
	}
	
	func size() -> UInt32 {
		8 + 4 * numberOfCommands + commands.map(\.size).sum()
	}
}

extension DEX.Packed.Event.Command {
	init?(_ command: DEX.Unpacked.Command) {
		guard let typeAndArguments = command.typeAndArguments else { return nil }
		(type, arguments) = typeAndArguments
		numberOfArguments = UInt32(arguments.count)
	}
	
	var size: UInt32 {
		12 + UInt32(arguments.count * 4)
	}
}

extension DEX.Unpacked.Command {
	var typeAndArguments: (UInt32, [Int32])? {
		switch self {
			case .known(let type, _, let arguments): (type, arguments)
			case .unknown(let type, let arguments): (type, arguments)
			case .comment: nil
		}
	}
}

// MARK: unpacked
extension DEX.Unpacked: ProprietaryFileData {
	static let fileExtension = ".dex"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> DEX.Packed {
		DEX.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: DEX.Packed, configuration: Configuration) throws {
		commands = try packed.events
			.map(\.commands)
			.recursiveMap { try Command($0, configuration: configuration) }
	}
	
	init(_ data: Datastream, configuration: Configuration) throws {
		let fileLength = data.bytes.endIndex - data.offset
		let string = try data.read(String.self, exactLength: fileLength)
		
		commands = try string
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.split(separator: "\n\n")
			.map {
				try $0.split(separator: "\n")
					.map { try DEX.Unpacked.Command($0, configuration: configuration) }
			}
	}
	
	func write(to data: Datawriter) {
		let string = commands
			.recursiveMap(String.init)
			.map { $0.joined(separator: "\n") }
			.joined(separator: "\n\n") + "\n"
		
		data.write(string, length: string.lengthOfBytes(using: .utf8))
	}
}

extension DEX.Unpacked.CommandDefinition: ExpressibleByStringInterpolation {
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
			case argument(Int, DEX.Unpacked.ArgumentType)
			case vector(Int, Int)
		}
		
		init(literalCapacity: Int, interpolationCount: Int) {
			chunks = []
			chunks.reserveCapacity(interpolationCount)
		}
		
		mutating func appendLiteral(_ literal: String) {
			chunks.append(.text(literal))
		}
		
		mutating func appendInterpolation(_ argumentNumber: Int, _ argumentType: DEX.Unpacked.ArgumentType) {
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
			.flatMap { (chunk: StringInterpolation.Chunk) -> [(index: Int, argumentType: DEX.Unpacked.ArgumentType)] in
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

extension DEX.Unpacked.Command {
	struct WrongArgumentCount: Error, CustomStringConvertible {
		var type: UInt32
		var expected: Int
		var actual: Int
		
		var description: String {
			"wrong number of arguments in binary for command \(.cyan)\(type)\(.normal): expected \(.green)\(expected)\(.normal), got \(.red)\(actual)\(.normal)"
		}
	}
	
	init(_ binaryCommand: DEX.Packed.Event.Command, configuration: Configuration) throws {
		if let definition = DEX.Unpacked.knownCommands(for: configuration)[binaryCommand.type] {
			// TODO: special case for 181?
			
			guard definition.argumentTypes.count == binaryCommand.arguments.count else {
				throw WrongArgumentCount(
					type: binaryCommand.type,
					expected: definition.argumentTypes.count,
					actual: binaryCommand.arguments.count
				)
			}
			
			self = .known(
				type: binaryCommand.type,
				definition: definition,
				arguments: binaryCommand.arguments
			)
		} else {
			self = .unknown(
				type: binaryCommand.type,
				arguments: binaryCommand.arguments
			)
		}
	}
	
	init(_ text: Substring, configuration: Configuration) throws(DEX.Unpacked.Command.ParseError) {
		if text.hasPrefix("// ") {
			self = .comment(String(text.dropFirst(3)))
			return
		} else if text.hasPrefix("//") {
			self = .comment(String(text.dropFirst(2)))
			return
		}
		
		guard let (arguments, textWithoutArguments) = extractAngleBrackets(from: text) else {
			throw .mismatchedAngleBrackets(requirement: text)
		}
		
		if let (commandType, knownCommand) = DEX.Unpacked.knownCommands(for: configuration).first(where: { $0.value.textWithoutArguments == textWithoutArguments }) {
			guard knownCommand.argumentIndicesFromText.count == arguments.count else {
				throw
					.incorrectArgumentCount(
					command: text,
					actual: arguments.count,
					expected: knownCommand.argumentIndicesFromText.count
				)
			}
			
			let reorderedArguments = knownCommand.argumentIndicesFromText.map { arguments[$0] }
			
			self = .known(
				type: commandType,
				definition: knownCommand,
				arguments: try zip(reorderedArguments, knownCommand.argumentTypes)
					.map { (argument, argumentType) throws(DEX.Unpacked.Command.ParseError) in
						guard let number = argumentType.parse(argument) else {
							throw .failedToParse(argument, in: text)
						}
						return number
					}
			)
		} else {
			guard text.hasPrefix("unknown") else {
				throw .unknownCommand(text)
			}
			
			let parsedArguments = try arguments.map { (argument) throws(DEX.Unpacked.Command.ParseError) in
				guard let value = DEX.Unpacked.ArgumentType.unknown.parse(argument) else {
					throw .failedToParse(argument, in: text)
				}
				return value
			}
			
			guard let commandType = parsedArguments.first else {
				throw .incorrectArgumentCount(command: text, actual: 0, expected: 1)
			}
			
			self = .unknown(
				type: UInt32(commandType),
				arguments: Array(parsedArguments.dropFirst())
			)
		}
	}
	
	func linesOfDialogue() -> [UInt32] {
		guard case .known(_, let definition, let arguments) = self else { return [] }
		
		return definition.argumentTypes
			.indices { $0 == .dialogue }
			.ranges
			.map(\.lowerBound)
			.map { UInt32(arguments[$0]) }
	}
}

extension DEX.Unpacked.Command.ParseError: CustomStringConvertible {
	var description: String {
		switch self {
			case .failedToParse(let text, in: let command):
				"failed to parse \(.red)<\(text)>\(.normal) in command '\(.cyan)\(command)\(.normal)'"
			case .incorrectArgumentCount(let command, let actual, let expected):
				"incorrect number of arguments in command '\(.cyan)\(command)\(.normal)', expected \(.green)\(expected)\(.normal), got \(.red)\(actual)\(.normal)"
			case .unknownCommand(let text):
				"unknown command: \(.red)\(text)\(.normal)"
			case .mismatchedAngleBrackets(let requirement):
				"requirement '\(.cyan)\(requirement)\(.normal)' has misimatching angle brackets"
		}
	}
}

extension String {
	init(_ command: DEX.Unpacked.Command) {
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
						.map(DEX.Unpacked.ArgumentType.unknown.format)
						.map { "<\($0)>" }
						.joined(separator: " ")
					
					return "unknown <\(type)>: \(formattedArguments)"
				}()
			case .comment(let string):
				string.split(separator: "\n", omittingEmptySubsequences: false)
					.map {
						if $0.isEmpty {
							"//"
						} else {
							"// " + $0
						}
					}
					.joined(separator: "\n")
		}
	}
}

extension DEX.Unpacked.ArgumentType {
	func parse(_ text: Substring) -> Int32? {
		switch self {
			case .boolean:         parseBoolean(text)
			case .entity:          entityIDs[text.lowercased()] ?? parsePrefix(text)
			case .degrees:         parseSuffix(text)
			case .flag:            parseFlag(text)
			case .dialogue:        parsePrefix(text)
			case .effect:          effectIDs[text.lowercased()] ?? parsePrefix(text)
			case .fixedPoint:      parseFixedPoint(text)
			case .fossil:          fossilIDs[text.lowercased()] ?? parsePrefix(text)
			case .frames:          parseSuffix(text)
			case .image:           imageIDs[text.lowercased()] ?? parsePrefix(text)
			case .integer:         Int32(text)
			case .map:             mapIDs[text.lowercased()] ?? parsePrefix(text)
			case .movement:        movementIDs[text.lowercased()] ?? parsePrefix(text)
			case .music:           parsePrefix(text)
			case .soundEffect:     soundEffectIDs[text.lowercased()] ?? parsePrefix(text)
			case .unknown:         parseUnknown(text)
			case .vivosaur:        vivosaurIDs[text.lowercased()] ?? parsePrefix(text)
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
	
	private func parseBoolean(_ text: Substring) -> Int32? {
		switch text {
			case "false": 0
			case "true": 1
			default: nil
		}
	}
	
	private func parseFlag(_ text: Substring) -> Int32? {
		let components = text.split(separator: " ")
		guard components.count == 2,
			  let unknown1 = Int32(components[0]),
			  let unknown2 = Int32(components[1])
		else { return nil }
		
		return unknown1 | unknown2 << 24
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
			case .boolean:     formatBoolean(number)
			case .entity:      entityNames[number] ?? "entity \(number)"
			case .degrees:     "\(number) degrees"
			case .flag:        formatFlag(number)
			case .dialogue:    "dialogue \(number)"
			case .effect:      effectNames[number] ?? "effect \(number)"
			case .fixedPoint:  formatFixedPoint(number)
			case .fossil:      fossilNames[number] ?? "fossil \(number)"
			case .frames:      "\(number) frames"
			case .image:       imageNames[number] ?? "image \(number)"
			case .integer:     "\(number)"
			case .map:         mapNames[number] ?? "map \(number)"
			case .movement:    movementNames[number] ?? "movement \(number)"
			case .music:       "music \(number)"
			case .soundEffect: soundEffectNames[number] ?? "sound effect \(number)"
			case .unknown:     formatUnknown(number)
			case .vivosaur:    vivosaurNames[number] ?? "vivosaur \(number)"
		}
	}
	
	private func formatBoolean(_ number: Int32) -> String {
		switch number {
			case 0: return "false"
			case 1: return "true"
			default:
				print("invalid boolean in DEX file: \(.red)\(number)\(.normal), expected \(.green)0\(.normal) or \(.green)1\(.normal)")
				waitForInput()
				fatalError()
		}
	}
	
	private func formatFlag(_ number: Int32) -> String {
		let unknown1 = UInt16(truncatingIfNeeded: number)
		let unknown2 = UInt8(truncatingIfNeeded: number >> 24)
		
		return "\(unknown1) \(unknown2)"
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
