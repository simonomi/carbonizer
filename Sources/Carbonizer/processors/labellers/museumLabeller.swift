func museumLabellerF(
	_ museumDefs: inout DML.Unpacked,
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	let text = try environment.get(\.text)
	
	for (index, vivosaur) in museumDefs.vivosaurs.enumerated() {
		museumDefs.vivosaurs[index]._description = text[Int(vivosaur.descriptionIndex)]
	}
}
