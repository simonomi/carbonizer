func dexRegionLabellerF(
	_ dex: inout DEX.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	let regionMaps = try environment.get(\.regionMaps)
	
	dex.commands = dex.commands.map {
		$0.reduce(into: []) { partialResult, command in
			for region in command.regions() {
				if !regionNames.keys.contains(region),
				   let map = regionMaps[region],
				   let mapName = mapNames[Int32(map)]
				{
					partialResult.append(.comment("region \(region) is in \(mapName)"))
				}
			}
			
			partialResult.append(command)
		}
	}
}
