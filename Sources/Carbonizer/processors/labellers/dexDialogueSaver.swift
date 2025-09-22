func dexDialogueSaver(
	_ dmg: inout DMG.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	let dexDialogue: [UInt32: String]
	if let dialogue = environment.dexDialogue {
		dexDialogue = dialogue
	} else {
		dexDialogue = try environment.get(\.conflictedDexDialogue)
			.resolvingMergeConflicts()
	}
	
	for index in dmg.strings.indices where dexDialogue.keys.contains(dmg.strings[index].index) {
		if dmg.strings[index].string != dexDialogue[dmg.strings[index].index]! {
			dmg.strings[index].string = dexDialogue[dmg.strings[index].index]!
		}
	}
}

extension [UInt32: WithPossibleMergeConflict<String>] {
	func resolvingMergeConflicts() -> [UInt32: String] {
		mapValues {
			switch $0 {
				case .one(let line):
					return line
				case .conflict(let lines):
					let lines = lines.sorted()
					
					let dialogueOptions = lines
						.enumerated()
						.map {
//							if configuration.useColor {
								"\(.cyan)\($0 + 1). \(.brightRed)'\($1)'\(.normal)"
//							} else {
//								"\($0 + 1). '\($1)'"
//							}
						}
						.joined(separator: "\n")
					
					// TODO: a way to ask this without manually printing/readlining
					print("Conflicting dialogue:\n\(dialogueOptions)\nWhich would you like to pick?", terminator: " ")
					
					var choice: String?
					repeat {
						guard let choiceNumber = readLine().flatMap(Int.init),
							  let line = lines[safely: choiceNumber - 1]
						else {
							print("Invalid response, please input a number matching one of the given options")
							continue
						}
						
						choice = line
					} while choice == nil
					
					return choice!
			}
		}
	}
}
