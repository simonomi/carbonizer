func dexDialogueLabellerF(
	_ dex: inout DEX.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	let allDialogue = try environment.get(\.dialogue)
	
	dex.commands = dex.commands.map {
		$0.reduce(into: []) { partialResult, command in
			let linesOfDialogue = command.linesOfDialogue()
				.map { allDialogue[$0] } // only dialogue 1139 in e0105 is nil
				.interspersed(with: "---")
				.compactMap { $0 }
			
			for lineOfDialogue in linesOfDialogue {
				partialResult.append(.comment(lineOfDialogue))
			}
			partialResult.append(command)
		}
	}
}
