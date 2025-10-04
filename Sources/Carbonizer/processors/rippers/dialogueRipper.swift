func dialogueRipperF(
	_ dmg: inout DMG.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	func uniqueKeys(_ firstLine: String, _ secondLine: String) throws -> String {
		if firstLine == secondLine {
			firstLine
		} else {
			throw DuplicateDialogue(firstLine: firstLine, secondLine: secondLine)
		}
	}
	
	let newStrings = try Dictionary(
		dmg.strings.map { ($0.index, $0.string) },
		uniquingKeysWith: uniqueKeys
	)
	
	if environment.dialogue == nil {
		environment.dialogue = newStrings
	} else {
		try environment.dialogue!.merge(newStrings, uniquingKeysWith: uniqueKeys)
	}
}

struct DuplicateDialogue: Error, CustomStringConvertible {
	var firstLine: String
	var secondLine: String
	
	var description: String {
		"the same line of dialogue is defined twice: \(.cyan)'\(firstLine)'\(.normal) and \(.cyan)'\(secondLine)'\(.normal)"
	}
}
