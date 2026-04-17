func regionMapRipperF(
	_ match: inout Match<UInt16>.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	if environment.regionMaps == nil {
		environment.regionMaps = [:]
	}
	
	for (region, map) in match.data.enumerated() {
		environment.regionMaps![Int32(region)] = map
	}
}
