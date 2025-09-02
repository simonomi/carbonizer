import BinaryParser
import Foundation

// TODO: parsing ffc with ff1's commands crashes instead of giving an error message
// WHILE WRITING??

enum DEX {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "DEX"
		var numberOfBlocks: UInt32
		var blockOffsetsStart: UInt32 = 0xC
		@Count(givenBy: \Self.numberOfBlocks)
		@Offset(givenBy: \Self.blockOffsetsStart)
		var blockOffsets: [UInt32]
		@Offsets(givenBy: \Self.blockOffsets)
		var blocks: [Block]
		
		@BinaryConvertible
		struct Block {
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
	
	struct Unpacked {
		var commands: [[Command]]
		
		enum ArgumentType {
			// TODO: add boolean and integer
			case character, degrees, dep, dialogue, effect, fixedPoint, fossil, frames, image, map, movement, music, soundEffect, unknown, vivosaur
			// notes on dep:
			// - two numbers, a u16 and u8 (is the u8 actually a u16?)
			// - u16 is lower bits, u8 is upper (>> 24)
			// - i list them u16 u8, should i swap that?
			// - 2nd number seems to be a type maybe?
			// - all 2nd numbers: 0, 2, 5, 6, 7, 8, 9, 10
			//   - 0: used for flag4s, dialogue with choice (both kinds) result
			//     dep: never (read with 8? maybe 9?)
			//   - 2: never
			//     dep: has played, has not played (blocks)
			//   - 3: never
			//     dep: has played, has not played (blocks)
			//   - 5: used for flag5 and flag6
			//     dep: 19 20 21 22 (boolean)
			//   - 6: used for flag5 and flag6
			//     dep: 19 20 21 22 (boolean)
			//   - 7: used for flag5
			//     dep: 20 21 (boolean)
			//   - 8: flag70
			//     dep: 7 8 9 10 11 13 14 15 17 18 19 21 (aka 7-11 13-15 17-19 21) (numerical AND boolean)
			//   - 9: flag70
			//     dep: 7 8 9 10 11 13 14 15 16 17 18 (aka 7-11 13-18) (aka numerical comparisons)
			//   - 10: flag5 flag6
			//     dep: flag19 flag21
			// <59 8> might be mask shop result? or maybe previous mask?
			// <4 9> might be current mask?
			// <2 9> == 1 means your case is size 8
			// <9 9> may be number of fossil rocks
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
			// 3: (#)
			//     7025 freezes camera focus (?)
			4:   "flag 4 \(0, .dep)",
			// wipes some stored dialogue answer. argument is the index in DEP
			// possibly dep too but the 2nd number is always 0
			// mark dialogue as not played!!!!!!!!!! (and possibly other things)
			// clear?? flag? but how is it different than flag 6?
			5:   "flag 5 \(0, .dep)",
			//     0xa00001d <29 10> makes it possible to save
			//     0x50000cf <207 5> activates wendy's dialogue and skips the hotel manager's first dialogue (softlock)
			//     0x5002d21 <11553 5> makes the samurai unable to battle
			//     activates DEP's unknown 19
			//     set true?
			//     memory types 5, 6, 7, 10
			6:   "flag 6 \(0, .dep)",
			//     0x500010f <271 5> is set with memory 6 when resetting name, and memory 5 when resetting vivosaur
			//     set false?
			//     memory types 5, 6, 10
			7:   "spawn \(0, .character) in \(1, .map) at \(2, 3, .vector) facing \(4, .degrees)",
			// 8:   (<character>, #)
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
			33:  "dialogue with choice \(1, .dialogue), storing result at \(0, .dep)",
			34:  "turn \(0, .character) to \(1, .degrees)",
			35:  "turn1 \(0, .character) to \(1, .degrees) over \(2, .frames), unknown: \(3, .unknown)",
			36:  "turn \(0, .character) towards \(1, .character) over \(2, .frames), unknown: \(3, .unknown)",
			37:  "turn2 \(0, .character) to \(1, .degrees) over \(2, .frames), unknown: \(3, .unknown)",
			38:  "turn \(0, .character) towards \(1, .character) over \(3, .frames), unknowns: \(2, .unknown) \(4, .unknown)",
			39:  "move \(0, .character) to \(1, .character) over \(2, .frames), unknown: \(3, .unknown)",
			// 41: (character?, #, frames?, #) another move-to?
			43:  "move \(0, .character) to position \(1, 2, .vector) over \(3, .frames), unknown: \(4, .unknown)",
			44:  "unknown 44: \(0, .character) \(1, 2, .vector) \(3, .frames) \(4, .unknown)",
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
			// 62: ()
			//    often after diologue choices
			//    often after battles
			//    after sue asks where to go, removing memory but keeping 62 makes camera low, but without 62 camera resets properly
			// 63: ()
			70:  "flag 70 \(0, .dep) \(1, .unknown)",
			//     writing to 0x9000007 <7 9> sets the player's profile pic (0-7 is a-h)
			//     memory location <7 9> is player profile pic
			//     set flag to?
			71:  "add \(1, .unknown) to flag \(0, .dep)",
			72:  "subtract \(1, .unknown) from flag \(0, .dep)",
			// 75 (flag, flag) (set flag to?)
			80:  "make \(0, .character) follow \(1, .character)",
			82:  "make \(0, .character) wander randomly, waiting between \(1, .frames) and \(2, .frames), walking speed \(3, .fixedPoint), distance up to \(4, .fixedPoint)",
			86: "make \(0, .character) chase player, detection range \(1, .fixedPoint), run distance \(2, .fixedPoint), chasing speed \(3, .fixedPoint), returning speed \(4, .fixedPoint), cooldown \(5, .frames)",
			90:  "set level for level-up animation \(0, .unknown)",
			97:  "set \(0, .vivosaur) fossil scores to \(1, .unknown) \(2, .unknown) \(3, .unknown) \(4, .unknown)", // TODO: number type
			// 106: mask shop
			107: "give \(0, .fossil), dark: \(1, .unknown), red: \(2, .unknown)", // TODO: 1 and 2 are booleans
			108: "give \(0, .fossil) without message, dark: \(1, .unknown), red: \(2, .unknown)", // TODO: 1 and 2 are booleans
			112: "play animation \(1, .unknown) on \(0, .character)", // TODO: number type
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
			136: "unknown 136: \(0, .character) \(1, .unknown)",
			//   1 24 - makes hunter blush
			138: "shake screen for \(2, .frames) with intensity: \(0, .unknown), gradual intensity: \(1, .unknown)", // TODO: make int types for these ?
			// 141: (#)
			142: "modify player name", // has back button
			143: "set player name",
			144: "dialogue \(0, .dialogue) with choice \(2, .dialogue), storing result at \(1, .dep)",
			150: "level-up animation",
			153: "fade in image \(0, .image) over \(1, .frames) on bottom screen, unknown: \(2, .unknown)", // TODO: is this actually top?
			154: "fade out image over \(0, .frames), unknown: \(1, .unknown)",
			155: "slide in image \(0, .image) over \(2, .frames), unknowns: \(1, .unknown) \(3, .unknown)",
			157: "fade in image \(0, .image) over \(2, .frames), unknowns: \(1, .fixedPoint) \(3, .unknown)",
			159: "fade in image \(0, .image) over \(1, .frames) on top screen, unknown: \(2, .unknown)", // TODO: is this actually bottom?
			// 160: (#, #)
			// 178: () suppresses "Fighter Area" corner tag?
			//     used in e0302 before a fossil battle
			191: "show revival screen for \(0, .vivosaur)",
			194: "unknown 194: \(0, .character)",
			// 195: (#, #)
			200: "start turning \(0, .character) to follow \(1, .character)",
			201: "stop turning \(0, .character)",
			206: "set \(0, .vivosaur) battle points to \(1, .unknown)" // TODO: number type
			
			// all the unknown commands as of rn 2 3 8 11 12 16 17 18 19 24 25 26 27 40 41 42 44 46 47 48 52 53 55 62 63 71 72 75 76 77 81 82 83 84 85 86 87 88 89 91 92 93 95 96 97 98 99 100 102 103 104 105 106 107 108 110 111 112 113 116 118 120 121 126 127 128 134 136 137 141 145 147 148 149 152 156 158 160 161 162 165 166 171 178 179 180 181 182 183 184 185 186 187 188 190 192 193 195 196 197 199 202 203 204 205 206
		]
		
		// any time these are updated, also update fftechwiki
		static let ffcCommands: [UInt32: CommandDefinition] = [
			71:  "dialogue \(0, .dialogue)",
			107: "unowned dialogue \(0, .dialogue)",
		]
		
		static func knownCommands(for configuration: CarbonizerConfiguration) -> [UInt32: CommandDefinition] {
			switch configuration.dexCommandList {
				case .ff1: ff1Commands
				case .ffc: ffcCommands
				case .none: [:]
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
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> DEX.Unpacked {
		DEX.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: DEX.Unpacked, configuration: CarbonizerConfiguration) {
		numberOfBlocks = UInt32(unpacked.commands.count)
		
		blocks = unpacked.commands.map(Block.init)
		
		blockOffsets = makeOffsets(
			start: blockOffsetsStart + numberOfBlocks * 4,
			sizes: blocks.map { $0.size() }
		)
	}
}

extension DEX.Packed.Block {
	init(_ commands: [DEX.Unpacked.Command]) {
		self.commands = commands.compactMap(Command.init)
		
		numberOfCommands = UInt32(self.commands.count)
		
		commandOffsets = makeOffsets(
			start: offsetsOffset + numberOfCommands * 4,
			sizes: self.commands.map(\.size)
		)
	}
	
	func size() -> UInt32 {
		8 + 4 * numberOfCommands + commands.map(\.size).sum()
	}
}

extension DEX.Packed.Block.Command {
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
	static let fileExtension = ".dex.txt"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> DEX.Packed {
		DEX.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: DEX.Packed, configuration: CarbonizerConfiguration) {
		commands = packed.blocks
			.map(\.commands)
			.recursiveMap { Command($0, configuration: configuration) }
	}
	
	init(_ data: Datastream, configuration: CarbonizerConfiguration) throws {
		let fileLength = data.bytes.endIndex - data.offset
		let string = try data.read(String.self, exactLength: fileLength)
		
		commands = try string
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
			.joined(separator: "\n\n")
		
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
	init(_ binaryCommand: DEX.Packed.Block.Command, configuration: CarbonizerConfiguration) {
		self = if let definition = DEX.Unpacked.knownCommands(for: configuration)[binaryCommand.type] {
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
	
	init(_ text: Substring, configuration: CarbonizerConfiguration) throws(DEX.Unpacked.Command.ParseError) {
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
			case .character:       parseLookupTable(characterNames, text: text) ?? parsePrefix(text)
			case .degrees:         parseSuffix(text)
			case .dep:             parseDEP(text)
			case .dialogue:        parsePrefix(text)
			case .effect:          parseLookupTable(effectNames, text: text) ?? parsePrefix(text)
			case .fixedPoint:      parseFixedPoint(text)
			case .fossil:          parseLookupTable(fossilNames, text: text) ?? parsePrefix(text)
			case .frames:          parseSuffix(text)
			case .image:           parseLookupTable(imageNames, text: text) ?? parsePrefix(text)
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
	
	private func parseDEP(_ text: Substring) -> Int32? {
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
			case .character:   "\(characterNames[number] ?? "character \(number)")"
			case .degrees:     "\(number) degrees"
			case .dep:         formatDEP(number)
			case .dialogue:    "dialogue \(number)"
			case .effect:      "\(effectNames[number] ?? "effect \(number)")"
			case .fixedPoint:  formatFixedPoint(number)
			case .fossil:      "\(fossilNames[number] ?? "fossil \(number)")"
			case .frames:      "\(number) frames"
			case .image:       "\(imageNames[number] ?? "image \(number)")"
			case .map:         "\(mapNames[number] ?? "map \(number)")"
			case .movement:    "\(movementNames[number] ?? "movement \(number)")"
			case .music:       "music \(number)"
			case .soundEffect: "sound effect \(number)"
			case .unknown:     formatUnknown(number)
			case .vivosaur:    "\(vivosaurNames[number] ?? "vivosaur \(number)")"
		}
	}
	
	private func formatDEP(_ number: Int32) -> String {
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
