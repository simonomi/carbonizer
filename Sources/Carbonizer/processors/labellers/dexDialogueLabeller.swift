func dexDialogueLabellerF(
	_ dex: inout DEX.Unpacked,
	in environment: inout Processor.Environment
) throws {
	guard let allDialogue = environment.dialogue else {
		throw ProcessorError.missingEnvironment("dialogue")
	}
	
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
