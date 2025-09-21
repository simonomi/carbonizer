func keyItemLabellerF(
	_ keyitemDefs: inout KIL.Unpacked,
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	let text = try environment.get(\.text)
	
	for (index, keyItem) in keyitemDefs.keyItems.enumerated() where keyItem != nil {
		keyitemDefs.keyItems[index]!._name = text[Int(keyItem!.nameIndex)]
		keyitemDefs.keyItems[index]!._description = text[Int(keyItem!.descriptionIndex)]
	}
}
