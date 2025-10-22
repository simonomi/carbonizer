func dexEventLabellerF(
	_ mar: inout MAR.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	guard mar.files.count == 1,
		  var dex = mar.files.first?.content as? DEX.Unpacked
	else {
		return
	}
	
	let eventIDs = try environment.get(\.eventIDs)
	
	guard let relevantEventIDs = eventIDs[String(mar.name.dropFirst())] else {
		return
	}
	
	for (eventIndex, eventID) in zip(dex.commands.indices, relevantEventIDs) {
		let comment: DEX.Unpacked.Command = .comment("event \(eventID)")
		dex.commands[eventIndex].insert(comment, at: 0)
	}
	
	mar.files[0].content = dex
}
