import BinaryParser

struct DEP {
	var blocks: [Block]
	
	enum ArgumentType {
		// TODO: rename dep to something more fitting (address, variable, ?) (and do the same in dex)
		case block, character, dep, door, firstNumberOnly, unknown, vivosaur
	}
	
	struct RequirementDefinition {
		var argumentTypes: [ArgumentType]
		var outputStringThingy: [OutputStringThingyChunk]
		var textWithoutArguments: [String]
		var argumentIndicesFromText: [Int] // this is the mapping of the binary order to text order TODO: rename
	}
	
	// note: requirements with variadic arguments cannot have ANY of their arguments out of order
	static let knownRequirements: [UInt32: RequirementDefinition] = [
		1:  "unconditional/always",
		2:  "talked to \(0, .character)",
		3:  "entered through \(0, .door)",
		13: "memory \(0, .dep) is \(1, .firstNumberOnly)",
//		    56 8-# 0    requires being fighter level #
//		    90 8-# 0    used to alternate hotel manager between dialogues
		16: "memory \(0, .dep) is less than \(1, .firstNumberOnly)", // wait, < or <=? probably <
//		    56 8-5 0    used to determine whether to spawn bullwort in his office
		19: "memory 19 \(0..., .dep)",
//		    requires an unknown 5
		21: "memory 21 \(0..., .dep)",
//		    requires NOT an unknown 5
		36: "\(0, .block) has played", // is op 2 always 2?
		38: "\(0, .block) has not played",
		41: "has \(0, .vivosaur)",
	]
	
	struct Block {
		var id: Int32
		var unknown1: Int32
		var unknown2: Int32
		var isComment: Bool
		var requirements: [Requirement]
		
		enum Requirement {
			case known(type: UInt32, definition: RequirementDefinition, arguments: [Argument])
			case unknown(type: UInt32, arguments: [Argument])
			case comment(String)

			struct Argument {
				var unknown1: UInt16
				var unknown2: UInt8
			}
		}
	}
	
	enum ParseError: Error {
		case failedToParse(Substring, in: Substring)
		case incorrectArgumentCount(requirement: Substring, actual: Int, expected: Int)
		case unknownRequirement(Substring)
		case blockMissingID(blockText: Substring)
		case mismatchedAngleBrackets(requirement: Substring)
	}
	
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "DEP"
		
		var blockCount: UInt32
		var blockOffsetsOffset: UInt32 = 0xC
		@Count(givenBy: \Self.blockCount)
		@Offset(givenBy: \Self.blockOffsetsOffset)
		var blockOffsets: [UInt32]
		@Offsets(givenBy: \Self.blockOffsets)
		var blocks: [Block]
		
		@BinaryConvertible
		struct Block {
			var id: Int32
			var unknown1: Int32
			var unknown2: Int32
			
			var requirementCount: UInt32
			var requirementOffsetsOffset: UInt32 = 0x14
			@Count(givenBy: \Self.requirementCount)
			@Offset(givenBy: \Self.requirementOffsetsOffset)
			var requirementOffsets: [UInt32]
			@Offsets(givenBy: \Self.requirementOffsets)
			var requirements: [Requirement]
			
			@BinaryConvertible
			struct Requirement {
				var type: UInt32
				var argumentCount: UInt32
				var argumentsOffset: UInt32 = 0xC
				@Count(givenBy: \Self.argumentCount)
				@Offset(givenBy: \Self.argumentsOffset)
				var arguments: [Argument]
				
				@BinaryConvertible
				struct Argument {
					var unknown1: UInt16
					@Padding(bytes: 1)
					var unknown2: UInt8
				}
			}
		}
	}
}

extension DEP: ProprietaryFileData {
	static let fileExtension = ".dep.txt"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	init(_ binary: Binary, configuration: CarbonizerConfiguration) {
		blocks = binary.blocks.map(Block.init)
	}
	
	init(_ data: Datastream) throws {
		let fileLength = data.bytes.endIndex - data.offset
		let string = try data.read(String.self, exactLength: fileLength)
		
		blocks = try string
			.split(separator: "\n\n")
			.map(DEP.Block.init)
	}
	
	func write(to data: Datawriter) {
		let string = blocks
			.map(String.init)
			.joined(separator: "\n\n")
		
		data.write(string, length: string.lengthOfBytes(using: .utf8))
	}
}

extension DEP.Block {
	init(_ binaryBlock: DEP.Binary.Block) {
		id = binaryBlock.id
		unknown1 = binaryBlock.unknown1
		unknown2 = binaryBlock.unknown2
		isComment = false
		requirements = binaryBlock.requirements.map(Requirement.init)
	}
}

extension DEP.Block.Requirement {
	init(_ binaryRequirement: DEP.Binary.Block.Requirement) {
		self = if let definition = DEP.knownRequirements[binaryRequirement.type] {
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
}

extension DEP.Block.Requirement.Argument {
	init(_ binaryArgument: DEP.Binary.Block.Requirement.Argument) {
		unknown1 = binaryArgument.unknown1
		unknown2 = binaryArgument.unknown2
	}
}

extension DEP.Binary: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	init(_ dep: DEP, configuration: CarbonizerConfiguration) {
		blocks = dep.blocks.compactMap(Block.init)
		blockCount = UInt32(blocks.count)
		blockOffsets = makeOffsets(
			start: blockOffsetsOffset + UInt32(blocks.count * 4),
			sizes: blocks.map { $0.size() }
		)
	}
}

extension DEP.Binary.Block {
	init?(_ depBlock: DEP.Block) {
		guard !depBlock.isComment else { return nil }
		
		id = depBlock.id
		unknown1 = depBlock.unknown1
		unknown2 = depBlock.unknown2
		
		requirements = depBlock.requirements.compactMap(Requirement.init)
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

extension DEP.Binary.Block.Requirement {
	init?(_ depRequirement: DEP.Block.Requirement) {
		switch depRequirement {
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

extension DEP.Binary.Block.Requirement.Argument {
	init(_ depArgument: DEP.Block.Requirement.Argument) {
		unknown1 = depArgument.unknown1
		unknown2 = depArgument.unknown2
	}
}

extension DEP.Block {
	init(_ text: Substring) throws(DEP.ParseError) {
		let lines = text.split(separator: "\n")
		let firstLine = lines.first!
		
		if firstLine.hasPrefix("// block") {
			isComment = true
		} else if firstLine.hasPrefix("block") {
			isComment = false
		} else {
			throw .blockMissingID(blockText: text)
		}
		
		guard let (blockArguments, _) = extractAngleBrackets(from: firstLine) else {
			throw .mismatchedAngleBrackets(requirement: text)
		}
		
		guard blockArguments.count == 3 else {
			throw .incorrectArgumentCount(
				requirement: text,
				actual: blockArguments.count,
				expected: 3
			)
		}
		
		let parsedBlockArguments = try blockArguments.map { (argument) throws(DEP.ParseError) in
			guard let number = Int32(argument) else {
				throw .failedToParse(argument, in: text)
			}
			return number
		}
		
		id = parsedBlockArguments[0]
		unknown1 = parsedBlockArguments[1]
		unknown2 = parsedBlockArguments[2]
		
		requirements = try lines
			.dropFirst()
			.map(DEP.Block.Requirement.init)
	}
}

extension DEP.Block.Requirement {
	init(_ text: Substring) throws(DEP.ParseError) {
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
		
		if let (requirementType, knownRequirement) = DEP.knownRequirements.first(where: { $0.value.textWithoutArguments == textWithoutArguments }) {
			let reorderedArguments: [Substring]
			
			if knownRequirement.outputStringThingy.contains(where: \.isVariadic) {
				reorderedArguments = arguments
			} else {
				guard knownRequirement.argumentIndicesFromText.count == arguments.count else {
					throw .incorrectArgumentCount(
						requirement: text,
						actual: arguments.count,
						expected: knownRequirement.argumentIndicesFromText.count
					)
				}
				
				reorderedArguments = knownRequirement.argumentIndicesFromText.map { arguments[$0] }
			}
			
			self = .known(
				type: requirementType,
				definition: knownRequirement,
				arguments: try zip(reorderedArguments, knownRequirement.argumentTypes)
					.map { (argument, argumentType) throws(DEP.ParseError) in
						guard let number = argumentType.parse(argument) else {
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
				.map { (argument) throws(DEP.ParseError) in
					guard let value = DEP.ArgumentType.unknown.parse(argument) else {
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
	init(_ block: DEP.Block) {
		let commentPrefix = block.isComment ? "// " : ""
		
		let header = "\(commentPrefix)block <\(block.id)>, unknowns: <\(block.unknown1)>, <\(block.unknown2)>"
		
		let requirements = block.requirements.map { String($0, isInComment: block.isComment) }
		
		self = ([header] + requirements).joined(separator: "\n")
	}
	
	init(_ requirement: DEP.Block.Requirement, isInComment: Bool) {
		guard !isInComment else {
			let originalText = String(requirement, isInComment: false)
			let comment: DEP.Block.Requirement = .comment(originalText)
			self = String(comment, isInComment: false)
			return
		}
		
		self = switch requirement {
			case .known(_, let definition, let arguments):
				definition.outputStringThingy.reduce(into: "") { partialResult, chunk in
					switch chunk {
						case .text(let text):
							partialResult += text
						case .argument(let index):
							partialResult += "<"
							partialResult += definition.argumentTypes[index].format(arguments[index])
							partialResult += ">"
						case .arguments(let indices):
							let argumentType = definition.argumentTypes[indices.lowerBound]
							partialResult += arguments[indices]
								.map(argumentType.format)
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
						.map(DEP.ArgumentType.unknown.format)
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

extension DEP.Block.Requirement.Argument: Equatable {}

extension DEP.ParseError: CustomStringConvertible {
	var description: String {
		switch self {
			case .failedToParse(let text, in: let requirement):
				"failed to parse \(.red)<\(text)>\(.normal) in requirement '\(.cyan)\(requirement)\(.normal)'"
			case .incorrectArgumentCount(let requirement, let actual, let expected):
				"incorrect number of arguments in requirement '\(.cyan)\(requirement)\(.normal)', expected \(.green)\(expected)\(.normal), got \(.red)\(actual)\(.normal)"
			case .unknownRequirement(let text):
				"unknown requirement: '\(.red)\(text)\(.normal)'"
			case .blockMissingID(blockText: let blockText):
				"first line of block is not block id: '\(.cyan)\(blockText)\(.normal)'"
			case .mismatchedAngleBrackets(let requirement):
				"requirement '\(.cyan)\(requirement)\(.normal)' has misimatching angle brackets"
		}
	}
}

extension DEP.RequirementDefinition: ExpressibleByStringInterpolation {
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
			case argument(Int, DEP.ArgumentType)
			case arguments(PartialRangeFrom<Int>, DEP.ArgumentType)
		}
		
		init(literalCapacity: Int, interpolationCount: Int) {
			chunks = []
			chunks.reserveCapacity(interpolationCount)
		}
		
		mutating func appendLiteral(_ literal: String) {
			chunks.append(.text(literal))
		}
		
		mutating func appendInterpolation(_ argumentNumber: Int, _ argumentType: DEP.ArgumentType) {
			chunks.append(.argument(argumentNumber, argumentType))
		}
		
		mutating func appendInterpolation(_ argumentRange: PartialRangeFrom<Int>, _ argumentType: DEP.ArgumentType) {
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
			.flatMap { (chunk: StringInterpolation.Chunk) -> [(index: Int, argumentType: DEP.ArgumentType)] in
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

extension DEP {
	static func checkKnownRequirements() {
		var allRequirementsWithoutArguments = Set<[String]>()
		
		for requirement in knownRequirements.values {
			guard !allRequirementsWithoutArguments.contains(requirement.textWithoutArguments) else {
				print("\(.red)duplicate command text for \(requirement.textWithoutArguments) >:(\(.normal)")
				preconditionFailure()
			}
			allRequirementsWithoutArguments.insert(requirement.textWithoutArguments)
		}
	}
}

extension DEP.ArgumentType {
	func parse(_ text: Substring) -> DEP.Block.Requirement.Argument? {
		switch self {
			case .block:           parseBlock(text)
			case .character:       parseLookupTable(characterNames, text: text) ?? parsePrefix(text)
			case .dep:             parseUnknown(text)
			case .door:            parseLookupTable(doorNames, text: text) ?? parsePrefix(text)
			case .firstNumberOnly: parseFirstNumberOnly(text)
			case .unknown:         parseUnknown(text)
			case .vivosaur:        parseLookupTable(vivosaurNames, text: text) ?? parsePrefix(text)
		}
	}
	
	private func parsePrefix(_ text: Substring) -> DEP.Block.Requirement.Argument? {
		text
			.split(whereSeparator: \.isWhitespace)
			.last
			.flatMap { UInt16($0) }
			.map { DEP.Block.Requirement.Argument(unknown1: $0, unknown2: 0) }
	}
	
//	private func parseSuffix(_ text: Substring) -> DEP.Block.Requirement.Argument? {
//		text
//			.split(whereSeparator: \.isWhitespace)
//			.first
//			.flatMap { UInt16($0) }
//			.map { DEP.Block.Requirement.Argument(unknown1: $0, unknown2: 0) }
//	}
	
	private func parseLookupTable(_ table: [Int32: String], text: Substring) -> DEP.Block.Requirement.Argument? {
		table
			.first { $0.value.caseInsensitiveEquals(text) }
			.map(\.key)
			.map(UInt16.init)
			.map { DEP.Block.Requirement.Argument(unknown1: $0, unknown2: 0) }
	}
	
	private func parseBlock(_ text: Substring) -> DEP.Block.Requirement.Argument? {
		if text.hasPrefix("block ") {
			parseUnknown(text.dropFirst(6))
		} else {
			parseUnknown(text)
		}
	}
	
	private func parseFirstNumberOnly(_ text: Substring) -> DEP.Block.Requirement.Argument? {
		UInt16(text)
			.map { DEP.Block.Requirement.Argument(unknown1: $0, unknown2: 0) }
	}
	
	private func parseUnknown(_ text: Substring) -> DEP.Block.Requirement.Argument? {
		let unknowns = text.split(separator: " ")
		
		guard unknowns.count == 2,
			  let unknown1 = UInt16(unknowns[0]),
			  let unknown2 = UInt8(unknowns[1])
		else { return nil }
		
		return DEP.Block.Requirement.Argument(unknown1: unknown1, unknown2: unknown2)
	}
	
	func format(_ argument: DEP.Block.Requirement.Argument) -> String {
		validate(argument)
		return switch self {
			case .block:           "block \(argument.unknown1) \(argument.unknown2)"
			case .character:       "\(characterNames[Int32(argument.unknown1)] ?? "character \(argument.unknown1)")"
			case .dep:             "\(argument.unknown1) \(argument.unknown2)"
			case .door:            "\(doorNames[Int32(argument.unknown1)] ?? "door \(argument.unknown1)")"
			case .firstNumberOnly: "\(argument.unknown1)"
			case .unknown:         "\(argument.unknown1) \(argument.unknown2)"
			case .vivosaur:        "\(vivosaurNames[Int32(argument.unknown1)] ?? "vivosaur \(argument.unknown1)")"
		}
	}
	
	func validate(_ argument: DEP.Block.Requirement.Argument) {
		switch self {
			case .character, .door, .firstNumberOnly, .vivosaur:
				// TODO: this should fail better
				precondition(argument.unknown2 == 0)
			default: ()
		}
	}
}
