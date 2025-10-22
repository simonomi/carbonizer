func mapLabellerF(
	_ map: inout MAP.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	let text = try environment.get(\.text)
	
	guard let japanese = text["japanese"] else {
		throw MissingTextFile(name: "japanese")
	}
	
	map._bannerText = japanese[safely: Int(map.bannerTextID)]
}
