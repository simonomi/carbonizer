func museumLabellerF(
	_ museumDefs: inout DML.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {let text = try environment.get(\.text)
	
	guard let japanese = text["japanese"] else {
		throw MissingTextFile(name: "japanese")
	}
	
	for (index, vivosaur) in museumDefs.vivosaurs.enumerated() {
		museumDefs.vivosaurs[index]._description = japanese[Int(vivosaur.descriptionIndex)]
	}
}
