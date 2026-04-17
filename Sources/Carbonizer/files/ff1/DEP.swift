import BinaryParser

enum DEP {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "DEP"
		
		var eventCount: UInt32
		var eventOffsetsOffset: UInt32 = 0xC
		@Count(givenBy: \Self.eventCount)
		@Offset(givenBy: \Self.eventOffsetsOffset)
		var eventOffsets: [UInt32]
		@Offsets(givenBy: \Self.eventOffsets)
		var events: [Event]
		
		@BinaryConvertible
		struct Event {
			var id: UInt32
			
			var requires: Criteria
			var canRunMultipleTimes: UInt32
			
			var requirementCount: UInt32
			var requirementOffsetsOffset: UInt32 = 0x14
			@Count(givenBy: \Self.requirementCount)
			@Offset(givenBy: \Self.requirementOffsetsOffset)
			var requirementOffsets: [UInt32]
			@Offsets(givenBy: \Self.requirementOffsets)
			var requirements: [Requirement]
			
			enum Criteria: UInt32, RawRepresentable {
				case all, any
			}
			
			@BinaryConvertible
			struct Requirement {
				var type: UInt32
				var argumentCount: UInt32
				var argumentsOffset: UInt32 = 0xC
				@Count(givenBy: \Self.argumentCount)
				@Offset(givenBy: \Self.argumentsOffset)
				var arguments: [Argument]
				
				// TODO: this should be a uint32 instead, right?
				// wait, is this backwards from DEX's dep?? how strange
				@BinaryConvertible
				struct Argument {
					var id: UInt16
					@Padding(bytes: 1) // or should this be a u8?
					var type: UInt8
				}
			}
		}
	}
	
	struct Unpacked {
		var events: [Event]
		
		enum ArgumentType {
			case event, entity, flag, region, integer, unknown, vivosaur
		}
		
		struct RequirementDefinition {
			var argumentTypes: [ArgumentType]
			var outputStringThingy: [OutputStringThingyChunk]
			var textWithoutArguments: [String]
			var argumentIndicesFromText: [Int] // this is the mapping of the binary order to text order TODO: rename
		}
		
		// requirements with variadic arguments may only have that variadic argument, and NO OTHERS
		// this is because of some kinda hacky code in DEP.Event.Requirement.init(_: Substring)
		static let knownRequirements: [UInt32: RequirementDefinition] = [
			1:  "always",
			2:  "talked to \(0, .entity)",
			3:  "collided with \(0, .region)",
			5:  "caught by \(0, .entity)",
			6:  "unknown 6 \(0, .vivosaur)",
			// in unused code to give the chickens
			7:  "flag \(0, .flag) equals \(1, .flag)",
			8:  "flag \(0, .flag) does not equal \(1, .flag)",
			9:  "flag \(0, .flag) is less than flag \(1, .flag)",
			10: "flag \(0, .flag) is less than or equal to flag \(1, .flag)",
			// 10 (flag, flag) yes for nil nil, not for 8 7 or 7 7 or 6 7 or 0 0
			11: "flag \(0, .flag) is greater than flag \(1, .flag)",
			// 12 is never used, but i bet its >=
			13: "flag \(0, .flag) is \(1, .integer)",
//			<56 8> <# 0>    requires being fighter level #
//			<90 8> <# 0>    used to alternate hotel manager between dialogues
			14: "flag \(0, .flag) is not \(1, .integer)",
			15: "flag \(0, .flag) is less than \(1, .integer)",
			// 15 // yes for nil 7, no for 7 7 and 6 7 and 8 7, pretty sure this is <, but not sure why weird
			// changing unknown2 affects this???
			16: "flag \(0, .flag) is less than or equal to \(1, .integer)",
			// wait, < or <=? probably <= right???
			// same test results as 9 and 15: triggers for nil but not once set??
//			<56 8> <5 0>    used to determine whether to spawn bullwort in his office
			// 13/16 memory types are 8 and 9
			17: "flag \(0, .flag) is greater than \(1, .integer)",
			// 17 (flag, number)? >?
			18: "flag \(0, .flag) is greater than or equal to \(1, .integer)",
			// 18 (flag, number)? this also seems like >=??
			19: "all flags true \(0..., .flag)",
//			requires an unknown 5 (&&, right?)
			// requires yes/first
			// require true?
			// notably NOT same as checking == 1 (or != 0)... right?
			// memory types 5, 6, and 10
			20: "any flag true \(0..., .flag)",
			// requires an unknown5, but || ?
			21: "all flags false \(0..., .flag)",
//			requires NOT an unknown 5 (&&)
			// requires no/second
			// require false?
			// notably NOT same as checking == 0... right?
			// memory types 5, 6, 7, and 10
			22: "any flag false \(0..., .flag)",
			// 22: requires NOT an unknown5, but ||
			23: "\(0, .entity) is spawned in",
			// used to trigger rex and snivels when you get close enough to them (chapter 4)
			36: "\(0..., .event) has played", // wait, if this is variadic, how is it different from the others?
			37: "at least one of \(0..., .event) has played",
			38: "\(0..., .event) has not played", // wait, if this is variadic, how is it different from the others?
			39: "none of \(0..., .event) have played",
			41: "has \(0, .vivosaur)",
		]
		
		struct Event {
			var id: UInt32
			var requires: Criteria
			var canRunMultipleTimes: Bool
			var isComment: Bool
			var requirements: [Requirement]
			
			enum Criteria: String {
				case all, any
			}
			
			enum Requirement {
				case known(type: UInt32, definition: RequirementDefinition, arguments: [Argument])
				case unknown(type: UInt32, arguments: [Argument])
				case comment(String)
				
				struct Argument {
					var id: UInt16
					var type: UInt8
				}
			}
		}
		
		enum ParseError: Error {
			case failedToParse(Substring, in: Substring)
			case incorrectArgumentCount(requirement: Substring, actual: Int, expected: Int)
			case unknownRequirement(Substring)
			case eventMissingID(eventText: Substring)
			case mismatchedAngleBrackets(requirement: Substring)
		}
	}
}

// MARK: packed
extension DEP.Packed: ProprietaryFileData {
	static let fileExtension = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> DEP.Unpacked {
		DEP.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: DEP.Unpacked, configuration: Configuration) {
		events = unpacked.events.compactMap(Event.init)
		eventCount = UInt32(events.count)
		eventOffsets = makeOffsets(
			start: eventOffsetsOffset + UInt32(events.count * 4),
			sizes: events.map { $0.size() }
		)
	}
}

extension DEP.Packed.Event {
	init?(_ unpacked: DEP.Unpacked.Event) {
		guard !unpacked.isComment else { return nil }
		
		id = unpacked.id
		requires = Criteria(unpacked.requires)
		canRunMultipleTimes = unpacked.canRunMultipleTimes ? 1 : 0
		
		requirements = unpacked.requirements.compactMap(Requirement.init)
		requirementCount = UInt32(requirements.count)
		requirementOffsets = makeOffsets(
			start: requirementOffsetsOffset + UInt32(requirements.count * 4),
			sizes: requirements.map(\.size)
		)
	}
	
	func size() -> UInt32 {
		20 + requirementCount * 4 + requirements.map(\.size).sum()
	}
}

extension DEP.Packed.Event.Criteria {
	init(_ unpacked: DEP.Unpacked.Event.Criteria) {
		self = switch unpacked {
			case .all: .all
			case .any: .any
		}
	}
}

extension DEP.Packed.Event.Requirement {
	init?(_ unpacked: DEP.Unpacked.Event.Requirement) {
		switch unpacked {
			case .known(let type, _, let arguments), .unknown(let type, let arguments):
				self.type = type
				argumentCount = UInt32(arguments.count)
				self.arguments = arguments.map(Argument.init)
			case .comment:
				return nil
		}
	}
	
	var size: UInt32 {
		12 + argumentCount * 4
	}
}

extension DEP.Packed.Event.Requirement.Argument {
	init(_ unpacked: DEP.Unpacked.Event.Requirement.Argument) {
		id = unpacked.id
		type = unpacked.type
	}
}

// MARK: unpacked
extension DEP.Unpacked: ProprietaryFileData {
	static let fileExtension = ".dep"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> DEP.Packed {
		DEP.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: DEP.Packed, configuration: Configuration) {
		events = packed.events.map(Event.init)
	}
	
	init(_ data: inout Datastream, configuration: Configuration) throws {
		let fileLength = data.bytes.endIndex - data.offset
		let string = try data.read(String.self, exactLength: fileLength)
		
		events = try string
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.split(separator: "\n\n")
			.map { try DEP.Unpacked.Event($0, configuration: configuration) }
	}
	
	func write(to data: Datawriter, configuration: Configuration) {
		let string = events
			.map { String($0, configuration: configuration) }
			.joined(separator: "\n\n") + "\n"
		
		data.write(string, length: string.lengthOfBytes(using: .utf8))
	}
}

extension DEP.Unpacked.Event {
	init(_ packed: DEP.Packed.Event) {
		id = packed.id
		requires = Criteria(packed.requires)
		canRunMultipleTimes = packed.canRunMultipleTimes > 0
		isComment = false
		requirements = packed.requirements.map(Requirement.init)
	}
}

extension DEP.Unpacked.Event.Criteria {
	init(_ packed: DEP.Packed.Event.Criteria) {
		self = switch packed {
			case .all: .all
			case .any: .any
		}
	}
}

extension DEP.Unpacked.Event.Requirement {
	init(_ binaryRequirement: DEP.Packed.Event.Requirement) {
		self = if let definition = DEP.Unpacked.knownRequirements[binaryRequirement.type] {
			.known(
				type: binaryRequirement.type,
				definition: definition,
				arguments: binaryRequirement.arguments.map(Argument.init)
			)
		} else {
			.unknown(
				type: binaryRequirement.type,
				arguments: binaryRequirement.arguments.map(Argument.init)
			)
		}
	}
	
	func regions() -> [Int32] {
		guard case .known(_, let definition, let arguments) = self else { return [] }
		
		// no requirements with regions are variadic, but if one is added, this will be wrong
		return definition.argumentTypes
			.indices { $0 == .region }
			.ranges
			.flatMap { $0.map { Int32(arguments[$0].id) } }
	}
	
	func events() -> [UInt32] {
		guard case .known(_, let definition, let arguments) = self else { return [] }
		
		return if definition.argumentTypes.count == 1,
				  definition.outputStringThingy.contains(where: \.isVariadic),
				  definition.argumentTypes[0] == .event
		{
			arguments
				.map(\.id)
				.map { UInt32($0) }
		} else {
			definition.argumentTypes
				.indices { $0 == .event }
				.ranges
				.flatMap { $0.map { UInt32(arguments[$0].id) } }
		}
	}
}

extension DEP.Unpacked.Event.Requirement.Argument {
	init(_ binaryArgument: DEP.Packed.Event.Requirement.Argument) {
		id = binaryArgument.id
		type = binaryArgument.type
	}
}

extension DEP.Unpacked.Event {
	init(_ text: Substring, configuration: Configuration) throws(DEP.Unpacked.ParseError) {
		var lines = text.split(separator: "\n")
		
		guard let headerLineIndex = lines.firstIndex(where: {
			$0.hasPrefix("event <") || $0.hasPrefix("// event <")
		}) else {
			throw .eventMissingID(eventText: text)
		}
		
		let firstLine = lines[headerLineIndex]
		
		let linesBeforeHeader = headerLineIndex - lines.startIndex
		
		for line in lines.prefix(linesBeforeHeader) {
			if !line.hasPrefix("//") {
				configuration.log(.warning, "DEP requirement comes before event line, will be skipped: \(.red)'\(line)'\(.normal)")
			}
		}
		
		lines.removeFirst(linesBeforeHeader + 1)
		
		isComment = firstLine.hasPrefix("//")
		
		guard let (eventArguments, _) = extractAngleBrackets(from: firstLine) else {
			throw .mismatchedAngleBrackets(requirement: text)
		}
		
		guard eventArguments.count == 3 else {
			throw .incorrectArgumentCount(
				requirement: text,
				actual: eventArguments.count,
				expected: 3
			)
		}
		
		typealias ParseError = DEP.Unpacked.ParseError
		
		id = try UInt32(eventArguments[0])
			.orElseThrow(ParseError.failedToParse(eventArguments[0], in: text))
		
		requires = try Criteria(rawValue: String(eventArguments[1]))
			.orElseThrow(ParseError.failedToParse(eventArguments[1], in: text))
		
		canRunMultipleTimes = try Bool(String(eventArguments[2]))
			.orElseThrow(ParseError.failedToParse(eventArguments[2], in: text))
		
		requirements = try lines
			.map { (line) throws(ParseError) -> Requirement in
				try Requirement(line, configuration: configuration)
			}
	}
}

extension DEP.Unpacked.Event.Requirement {
	init(_ text: Substring, configuration: Configuration) throws(DEP.Unpacked.ParseError) {
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
		
		if let (requirementType, knownRequirement) = DEP.Unpacked.knownRequirements.first(where: { $0.value.textWithoutArguments == textWithoutArguments }) {
			let reorderedArguments: [Substring]
			let argumentTypes: [DEP.Unpacked.ArgumentType]
			
			if knownRequirement.outputStringThingy.contains(where: \.isVariadic) {
				reorderedArguments = arguments
				
				let variadicArgumentType = knownRequirement.argumentTypes.first!
				argumentTypes = Array(repeating: variadicArgumentType, count: arguments.count)
			} else {
				guard knownRequirement.argumentIndicesFromText.count == arguments.count else {
					throw .incorrectArgumentCount(
						requirement: text,
						actual: arguments.count,
						expected: knownRequirement.argumentIndicesFromText.count
					)
				}
				
				reorderedArguments = knownRequirement.argumentIndicesFromText.map { arguments[$0] }
				argumentTypes = knownRequirement.argumentTypes
			}
			
			self = .known(
				type: requirementType,
				definition: knownRequirement,
				arguments: try zip(reorderedArguments, argumentTypes)
					.map { (argument, argumentType) throws(DEP.Unpacked.ParseError) in
						guard let number = argumentType.parse(
							argument,
							for: configuration.game
						) else {
							throw .failedToParse(argument, in: text)
						}
						return number
					}
			)
		} else {
			guard text.hasPrefix("unknown") else {
				throw .unknownRequirement(text)
			}
			
			guard let requirementTypeText = arguments.first else {
				throw .incorrectArgumentCount(requirement: text, actual: 0, expected: 1)
			}
			
			guard let requirementType = UInt32(requirementTypeText) else {
				throw .failedToParse(requirementTypeText, in: text)
			}
			
			let parsedArguments = try arguments
				.dropFirst()
				.map { (argument) throws(DEP.Unpacked.ParseError) in
					guard let value = DEP.Unpacked.ArgumentType.unknown.parse(
						argument,
						for: configuration.game
					) else {
						throw .failedToParse(argument, in: text)
					}
					return value
				}
			
			self = .unknown(
				type: requirementType,
				arguments: Array(parsedArguments)
			)
		}
	}
}

extension String {
	init(_ event: DEP.Unpacked.Event, configuration: Configuration) {
		let labelPrefix = eventLabels[event.id].map { "// \($0)\n" } ?? ""
		
		let commentPrefix = event.isComment ? "// " : ""
		
		let header = "\(labelPrefix)\(commentPrefix)event <\(event.id)>, requires: <\(event.requires)>, can run multiple times: <\(event.canRunMultipleTimes)>"
		
		let requirements = event.requirements.map {
			String($0, configuration: configuration, isInComment: event.isComment)
		}
		
		self = ([header] + requirements).joined(separator: "\n")
	}
	
	init(
		_ requirement: DEP.Unpacked.Event.Requirement,
		configuration: Configuration,
		isInComment: Bool
	) {
		guard !isInComment else {
			let originalText = String(requirement, configuration: configuration, isInComment: false)
			let comment: DEP.Unpacked.Event.Requirement = .comment(originalText)
			self = String(comment, configuration: configuration, isInComment: false)
			return
		}
		
		if case .known(let type, let definition, let arguments) = requirement,
		   !definition.outputStringThingy.contains(where: { $0.isVariadic })
		{
			assert(definition.argumentTypes.count == arguments.count, "argument count for command \(type) doesnt match that in binary: definition \(definition.argumentTypes.count), binary \(arguments.count)")
		}
		
		self = switch requirement {
			case .known(_, let definition, let arguments):
				definition.outputStringThingy.reduce(into: "") { partialResult, chunk in
					switch chunk {
						case .text(let text):
							partialResult += text
						case .argument(let index):
							partialResult += "<"
							partialResult += definition.argumentTypes[index].format(
								arguments[index],
								for: configuration.game
							)
							partialResult += ">"
						case .arguments(let indices):
							let argumentType = definition.argumentTypes[indices.lowerBound]
							partialResult += arguments[indices]
								.map { argumentType.format($0, for: configuration.game) }
								.map { "<\($0)>" }
								.joined(separator: " ")
					}
				}
			case .unknown(let type, []):
				"unknown <\(type)>"
			case .unknown(let type, let arguments):
				{
					// TODO: make this good
					let formattedArguments = arguments
						.map { DEP.Unpacked.ArgumentType.unknown.format($0, for: configuration.game) }
						.map { "<\($0)>" }
						.joined(separator: " ")
					
					return "unknown <\(type)>: \(formattedArguments)"
				}()
			case .comment(let string):
				("// " + string)
					.replacing("\n", with: "\n// ")
					.replacing(/\ *\n/, with: "\n")
					.replacing(/\ $/, with: "")
		}
	}
}

extension DEP.Unpacked.Event.Requirement.Argument: Equatable {}

extension DEP.Unpacked.ParseError: CustomStringConvertible {
	var description: String {
		switch self {
			case .failedToParse(let text, in: let requirement):
				"failed to parse \(.red)<\(text)>\(.normal) in requirement '\(.cyan)\(requirement)\(.normal)'"
			case .incorrectArgumentCount(let requirement, let actual, let expected):
				"incorrect number of arguments in requirement '\(.cyan)\(requirement)\(.normal)', expected \(.green)\(expected)\(.normal), got \(.red)\(actual)\(.normal)"
			case .unknownRequirement(let text):
				"unknown requirement: '\(.red)\(text)\(.normal)'"
			case .eventMissingID(eventText: let eventText):
				"first line of event is not event id: '\(.cyan)\(eventText)\(.normal)'"
			case .mismatchedAngleBrackets(let requirement):
				"requirement '\(.cyan)\(requirement)\(.normal)' has misimatching angle brackets"
		}
	}
}

extension DEP.Unpacked.RequirementDefinition: ExpressibleByStringInterpolation {
	enum OutputStringThingyChunk {
		case text(String)
		case argument(Int)
		case arguments(PartialRangeFrom<Int>)
		
		init(_ stringInterpolationChunk: StringInterpolation.Chunk) {
			self = switch stringInterpolationChunk {
				case .text(let text): .text(text)
				case .argument(let index, _): .argument(index)
				case .arguments(let indices, _): .arguments(indices)
			}
		}
		
		var isVariadic: Bool {
			switch self {
				case .arguments: true
				case .text, .argument: false
			}
		}
	}
	
	struct StringInterpolation: StringInterpolationProtocol {
		var chunks: [Chunk]
		
		enum Chunk {
			case text(String)
			case argument(Int, DEP.Unpacked.ArgumentType)
			case arguments(PartialRangeFrom<Int>, DEP.Unpacked.ArgumentType)
		}
		
		init(literalCapacity: Int, interpolationCount: Int) {
			chunks = []
			chunks.reserveCapacity(interpolationCount)
		}
		
		mutating func appendLiteral(_ literal: String) {
			chunks.append(.text(literal))
		}
		
		mutating func appendInterpolation(_ argumentNumber: Int, _ argumentType: DEP.Unpacked.ArgumentType) {
			chunks.append(.argument(argumentNumber, argumentType))
		}
		
		mutating func appendInterpolation(_ argumentRange: PartialRangeFrom<Int>, _ argumentType: DEP.Unpacked.ArgumentType) {
			chunks.append(.arguments(argumentRange, argumentType))
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
			.flatMap { (chunk: StringInterpolation.Chunk) -> [(index: Int, argumentType: DEP.Unpacked.ArgumentType)] in
				switch chunk {
					case .text: []
					case .argument(let index, let argumentType): [(index, argumentType)]
					case .arguments(let indices, let argumentType): [(indices.lowerBound, argumentType)]
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
				case .arguments(let indices, _): [indices.lowerBound]
			}
		}
		argumentIndicesFromText = badthingArgumentIndicesFromText.indices.map {
			badthingArgumentIndicesFromText.firstIndex(of: $0)!
		}
	}
}

extension DEP.Unpacked.ArgumentType {
	func parse(
		_ text: Substring,
		for game: Configuration.Game
	) -> DEP.Unpacked.Event.Requirement.Argument? {
		switch self {
			case .event:           parseEvent(text, for: game)
			case .entity:          parseLookupTable(entityIDs, text: text) ?? parsePrefix(text)
			case .flag:            parseFlag(text, for: game)
			case .region:          parseLookupTable(regionIDs, text: text) ?? parsePrefix(text)
			case .integer:         parseInteger(text)
			case .unknown:         parseFlag(text, for: game)
			case .vivosaur:        parseLookupTable(vivosaurIDs, text: text) ?? parsePrefix(text)
		}
	}
	
	func format(
		_ argument: DEP.Unpacked.Event.Requirement.Argument,
		for game: Configuration.Game
	) -> String {
		validate(argument)
		return switch self {
			case .event:           "event \(formatFlag(argument, for: game))"
			case .entity:          "\(entityNames[Int32(argument.id)] ?? "entity \(argument.id)")"
			case .flag:            formatFlag(argument, for: game)
			case .region:          "\(regionNames[Int32(argument.id)] ?? "region \(argument.id)")"
			case .integer:         "\(argument.id)"
			case .unknown:         "\(argument.id) \(argument.type)"
			case .vivosaur:        "\(vivosaurNames[Int32(argument.id)] ?? "vivosaur \(argument.id)")"
		}
	}
	
	func validate(_ argument: DEP.Unpacked.Event.Requirement.Argument) {
		switch self {
			case .entity, .region, .integer, .vivosaur:
				// TODO: this should fail better
				precondition(argument.type == 0)
			default: ()
		}
	}
}

fileprivate func parsePrefix(_ text: Substring) -> DEP.Unpacked.Event.Requirement.Argument? {
	text
		.split(whereSeparator: \.isWhitespace)
		.last
		.flatMap { UInt16($0) }
		.map { DEP.Unpacked.Event.Requirement.Argument(id: $0, type: 0) }
}

fileprivate func parseLookupTable(_ table: [String: Int32], text: Substring) -> DEP.Unpacked.Event.Requirement.Argument? {
	table[text.lowercased()]
		.map(UInt16.init)
		.map { DEP.Unpacked.Event.Requirement.Argument(id: $0, type: 0) }
}

fileprivate func parseEvent(
	_ text: Substring,
	for game: Configuration.Game
) -> DEP.Unpacked.Event.Requirement.Argument? {
	if text.hasPrefix("event ") {
		parseFlag(text.dropFirst(6), for: game)
	} else {
		parseFlag(text, for: game)
	}
}

fileprivate func parseInteger(_ text: Substring) -> DEP.Unpacked.Event.Requirement.Argument? {
	UInt16(text).map { DEP.Unpacked.Event.Requirement.Argument(id: $0, type: 0) }
}

fileprivate func parseFlag(
	_ text: Substring,
	for game: Configuration.Game
) -> DEP.Unpacked.Event.Requirement.Argument? {
	if text.starts(with: "key item ") {
		return UInt16(text.dropFirst(9)).map {
			DEP.Unpacked.Event.Requirement.Argument(
				id: $0,
				type: 6
			)
		}
	} else if text.starts(with: "mask ") {
		return UInt16(text.dropFirst(5)).map {
			DEP.Unpacked.Event.Requirement.Argument(
				id: $0,
				type: 7
			)
		}
	} else {
		let id = switch game {
			case .ff1: ff1FlagIDs[text.lowercased()]
			case .ffc: ffcFlagIDs[text.lowercased()]
		}
		
		return id.map { DEP.Unpacked.Event.Requirement.Argument($0) }
			?? parseRawFlag(text)
	}
}

extension DEP.Unpacked.Event.Requirement.Argument {
	init(_ raw: Int32) {
		id = UInt16(truncatingIfNeeded: raw)
		type = UInt8(truncatingIfNeeded: raw >> 24)
	}
}

fileprivate func parseRawFlag(
	_ text: Substring
) -> DEP.Unpacked.Event.Requirement.Argument? {
	let components = text.split(separator: " ")
	guard components.count == 2,
		  let id = UInt16(components[0]),
		  let type = UInt8(components[1])
	else { return nil }
	
	return DEP.Unpacked.Event.Requirement.Argument(id: id, type: type)
}

fileprivate func formatFlag(
	_ argument: DEP.Unpacked.Event.Requirement.Argument,
	for game: Configuration.Game
) -> String {
	return switch argument.type {
		case 6: "key item \(argument.id)"
		case 7: "mask \(argument.id)"
		default:
			switch game {
				case .ff1: ff1FlagNames[argument.type]?[UInt32(argument.id)] ?? "\(argument.id) \(argument.type)"
				case .ffc: ffcFlagNames[argument.type]?[UInt32(argument.id)] ?? "\(argument.id) \(argument.type)"
			}
	}
}
