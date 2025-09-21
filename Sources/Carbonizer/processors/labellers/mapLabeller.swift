func mapLabellerF(
	_ map: inout MAP.Unpacked,
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	let text = try environment.get(\.text)
	
	map._bannerText = text[safely: Int(map.bannerTextID)]
}
