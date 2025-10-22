func maskNameLabellerF(
	_ headmaskDefs: inout HML.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {let text = try environment.get(\.text)
	
	guard let japanese = text["japanese"] else {
		throw MissingTextFile(name: "japanese")
	}
	
	for (index, mask) in headmaskDefs.masks.enumerated() {
		headmaskDefs.masks[index]._name = japanese[Int(mask.name)]
		headmaskDefs.masks[index]._japaneseDebugName = japanese[Int(mask.japaneseDebugName)]
	}
}
