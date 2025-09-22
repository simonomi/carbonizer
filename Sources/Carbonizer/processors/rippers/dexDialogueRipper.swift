func dexDialogueRipperF(
	_ dex: inout DEX.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	if environment.conflictedDexDialogue == nil {
		environment.conflictedDexDialogue = [:]
	}
	
	var currentComments: [String] = []
	
	for event in dex.commands {
		for command in event {
			if case .comment(let string) = command {
				guard string.wholeMatch(of: /block \d+/) == nil else { continue }
				
				currentComments.append(string)
			} else if command.linesOfDialogue().isNotEmpty {
				let newLines = currentComments
					.split(separator: "---", omittingEmptySubsequences: false)
					.map {
						$0.joined(separator: "\n")
					}
				
				if newLines.isEmpty {
					currentComments.removeAll(keepingCapacity: true)
					continue
				}
				
				let dialogueNumbers = command.linesOfDialogue()
				
				guard dialogueNumbers.count == newLines.count else {
					throw MismatchedDialogueCounts(newLines: newLines, dialogueNumbers: dialogueNumbers)
				}
				
				for (dialogueNumber, newLine) in zip(dialogueNumbers, newLines) {
					if let existingLine = environment.conflictedDexDialogue![dialogueNumber] {
						environment.conflictedDexDialogue![dialogueNumber] = WithPossibleMergeConflict(existingLine, .one(newLine))
					} else {
						environment.conflictedDexDialogue![dialogueNumber] = .one(newLine)
					}
				}
				currentComments.removeAll(keepingCapacity: true)
			} else {
				currentComments.removeAll(keepingCapacity: true)
			}
		}
	}
}

struct MismatchedDialogueCounts: Error, CustomStringConvertible {
	var newLines: [String]
	var dialogueNumbers: [UInt32]
	
	var description: String {
		"The number of lines of dialogue (\(newLines.count)) does not match the number of dialogues used in the command (\(dialogueNumbers.count)). Lines of dialogue: \(newLines), dialogues used: \(dialogueNumbers)"
	}
}

enum WithPossibleMergeConflict<Wrapped: Hashable> {
	case one(Wrapped)
	case conflict(Set<Wrapped>)
	
	init(_ first: Self, _ second: Self) {
		self = switch (first, second) {
			case (.one(let firstWrapped), .one(let secondWrapped)) where firstWrapped == secondWrapped:
				.one(firstWrapped)
			case (.one(let firstWrapped), .one(let secondWrapped)):
					.conflict([firstWrapped, secondWrapped])
			case (.one(let new), .conflict(let existing)), (.conflict(let existing), .one(let new)):
				if existing.contains(new) {
					.conflict(existing)
				} else {
					.conflict(existing.inserting(new))
				}
			case (.conflict(let firsts), .conflict(let seconds)):
					.conflict(firsts.union(seconds))
		}
	}
}
