func maskNameLabellerF(
	_ headmaskDefs: inout HML.Unpacked,
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	let text = try environment.get(\.text)
	
	for (index, mask) in headmaskDefs.masks.enumerated() {
		headmaskDefs.masks[index]._name = text[Int(mask.name)]
		headmaskDefs.masks[index]._japaneseDebugName = text[Int(mask.japaneseDebugName)]
	}
}
