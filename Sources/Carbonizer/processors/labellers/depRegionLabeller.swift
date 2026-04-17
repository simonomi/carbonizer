func depRegionLabellerF(
	_ dep: inout DEP.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	let regionMaps = try environment.get(\.regionMaps)
	
	for eventIndex in dep.events.indices {
		dep.events[eventIndex].requirements = dep.events[eventIndex].requirements
			.reduce(into: []) { partialResult, requirement in
				for region in requirement.regions() {
					if !regionNames.keys.contains(region),
					   let map = regionMaps[region],
					   let mapName = mapNames[Int32(map)]
					{
						partialResult.append(.comment("region \(region) is in \(mapName)"))
					}
				}
				
				partialResult.append(requirement)
			}
	}
}
