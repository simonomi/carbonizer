func ffcCreatureLabellerF(
	_ dcl: inout DCL_FFC.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	let text = try environment.get(\.text)
	
	guard let vivosaurNames = text["text_dino_short_name"] else {
		throw MissingTextFile(name: "text_dino_short_name")
	}
	
	for index in dcl.vivosaurs.indices {
		if let nameID = dcl.vivosaurs[index]?.defaultNameID,
		   let name = vivosaurNames[safely: Int(nameID)]
		{
			dcl.vivosaurs[index]!._defaultName = name
		}
	}
}
