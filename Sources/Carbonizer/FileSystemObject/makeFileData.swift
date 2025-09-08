import BinaryParser

func makeFileData(
	name: String,
	data: Datastream,
	configuration: CarbonizerConfiguration
) throws -> (any ProprietaryFileData)? {
	if configuration.fileTypes.contains("_match") {
		if name == "region_center_match" {
			return try Match<UInt32>.Packed.init(data, configuration: configuration)
		} else if name.hasSuffix("_match") {
			return try Match<UInt16>.Packed.init(data, configuration: configuration)
		} else if name == "region_center_match.json" {
			return try Match<UInt32>.Unpacked.init(data, configuration: configuration)
		} else if name.hasSuffix("_match.json") {
			return try Match<UInt16>.Unpacked.init(data, configuration: configuration)
		}
	}
	
	if let fileType = configuration.fileType(name: name) {
		return try fileType.init(data, configuration: configuration)
	}
	
	let dataCopy = Datastream(data) // copy to not modify
	// most ff file types have 3-byte magic bytes with a null terminator, but
	// some (SDAT, ffc DMSK) have 4-bytes with no terminator. this won't match
	// a file if it's exactly 3 bytes long, but that should be ok... right?
	if let magicBytes = try? dataCopy.read(String.self, length: 4),
		magicBytes.isNotEmpty,
		let fileType = configuration.fileType(magicBytes: magicBytes)
	{
		return try fileType.init(data, configuration: configuration)
	}
	
	return nil
}
