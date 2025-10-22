func keyItemLabellerF(
	_ keyitemDefs: inout KIL.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	let text = try environment.get(\.text)
	
	let fileName = switch configuration.game {
		case .ff1: "japanese"
		case .ffc: "text_keyitem_name"
	}
	
	guard let keyItemNames = text[fileName] else {
		throw MissingTextFile(name: fileName)
	}
	
	// for some reason, ffc's indices don't start at 0, even though
	// they get their own text file, so manually offset it ig
	let offset = switch configuration.game {
		case .ff1: 0
		case .ffc: 4247
	}
	
	for (index, keyItem) in keyitemDefs.keyItems.enumerated() where keyItem != nil {
		keyitemDefs.keyItems[index]!._name = keyItemNames[safely: Int(keyItem!.nameIndex) - offset]
		keyitemDefs.keyItems[index]!._description = keyItemNames[safely: Int(keyItem!.descriptionIndex) - offset]
	}
}
