import BinaryParser

func makeFileData(
	name: String,
	data: Datastream,
	configuration: Configuration
) throws -> (any ProprietaryFileData)? {
	// TODO: (how) does this work?? shouldnt the name be nil bc its in a mar??
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
	
	// has the magic bytes DCL, but doesn't match creature_defs
	// TODO: look into this and see what format it *does* have, can this be reconciled?
	if name == "donate_creature_defs" {
		return nil
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
