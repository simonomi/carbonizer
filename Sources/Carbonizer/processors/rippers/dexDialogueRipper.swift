func dexDialogueRipper(_ fileSystemObject: any FileSystemObject) throws -> [UInt32: WithPossibleMergeConflict<String>] {
	switch fileSystemObject {
		case is BinaryFile, is MAR.Packed, is NDS.Packed:
			[:]
		case let file as ProprietaryFile:
			try ripDEXDialogue(file.data)
		case let mar as MAR.Unpacked:
			try mar.files.map(\.content).map(ripDEXDialogue).gentlyMerged()
		case let nds as NDS.Unpacked:
			try nds.contents.map(dexDialogueRipper).gentlyMerged()
		case let folder as Folder:
			try folder.contents.map(dexDialogueRipper).gentlyMerged()
		default:
			fatalError("unexpected fileSystemObject type: \(type(of: fileSystemObject))")
	}
}

struct MismatchedDialogueCounts: Error, CustomStringConvertible {
	var newLines: [String]
	var dialogueNumbers: [UInt32]
	
	var description: String {
		"The number of lines of dialogue (\(newLines.count)) does not match the number of dialogues used in the command (\(dialogueNumbers.count)). Lines of dialogue: \(newLines), dialogues used: \(dialogueNumbers)"
	}
}

fileprivate func ripDEXDialogue(_ data: any ProprietaryFileData) throws -> [UInt32: WithPossibleMergeConflict<String>] {
	guard let dex = data as? DEX.Unpacked else { return [:] }
	
	var updatedDialogue: [UInt32: WithPossibleMergeConflict<String>] = [:]
	
	var currentComments: [String] = []
	
	for block in dex.commands {
		for command in block {
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
					if let existingLine = updatedDialogue[dialogueNumber] {
						updatedDialogue[dialogueNumber] = WithPossibleMergeConflict(existingLine, .one(newLine))
					} else {
						updatedDialogue[dialogueNumber] = .one(newLine)
					}
				}
				currentComments.removeAll(keepingCapacity: true)
			} else {
				currentComments.removeAll(keepingCapacity: true)
			}
		}
	}
	
	return updatedDialogue
}

fileprivate extension [[UInt32: WithPossibleMergeConflict<String>]] {
	func gentlyMerged() -> [UInt32: WithPossibleMergeConflict<String>] {
		reduce([:]) { partialResult, dialogue in
			partialResult.merging(dialogue) {
				WithPossibleMergeConflict($0, $1)
			}
		}
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
