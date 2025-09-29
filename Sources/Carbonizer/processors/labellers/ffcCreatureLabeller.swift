func ffcCreatureLabellerF(
	_ dcl: inout DCL_FFC.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	let ffcText = try environment.get(\.ffcText)
	
	guard let vivosaurNames = ffcText["text_dino_short_name"] else {
		throw MissingShortNameText()
	}
	
	for index in dcl.vivosaurs.indices {
		if let nameID = dcl.vivosaurs[index]?.defaultNameID,
		   let name = vivosaurNames[safely: Int(nameID)]
		{
			dcl.vivosaurs[index]!._defaultName = name
		}
	}
}

struct MissingShortNameText: Error, CustomStringConvertible {
	var description: String {
		"couldn't find unpacked \(.red)text_dino_short_name\(.normal) in \(.cyan)text/\(.normal)"
	}
}
