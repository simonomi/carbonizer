import BinaryParser

func makeFileData(
	name: String,
	data: Datastream,
	configuration: CarbonizerConfiguration
) throws -> (any ProprietaryFileData)? {
	let allFileTypes: [String: any ProprietaryFileData.Type] = [
		"3CL": TCL.Unpacked.self,
		"BBG": BBG.Unpacked.self,
		"BCO": BCO.Unpacked.self,
		"CHR": CHR.Unpacked.self,
		"DBS": DBS.Unpacked.self,
		"DCL": DCL.Unpacked.self,
		"DEP": DEP.Unpacked.self,
		"DEX": DEX.Unpacked.self,
		"DMG": DMG.Unpacked.self,
		"DML": DML.Unpacked.self,
		"DMS": DMS.Unpacked.self,
		"DTX": DTX.Unpacked.self,
		"ECS": ECS.Unpacked.self,
		"GRD": GRD.Unpacked.self,
		"HML": HML.Unpacked.self,
		"KIL": KIL.Unpacked.self,
		"MAP": MAP.Unpacked.self,
		"MFS": MFS.Unpacked.self,
		"MM3": MM3.Unpacked.self,
		"MMS": MMS.Unpacked.self,
		"MPM": MPM.Unpacked.self,
		"RLS": RLS.Unpacked.self,
		"SDAT": SDAT.Unpacked.self,
		"SHP": SHP.Unpacked.self,
	]
	
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
	
	// TODO: doing this for every file is slow!
	let fileTypes: [any ProprietaryFileData.Type] = allFileTypes
		.filter { (fileTypeName, _) in
			configuration.fileTypes.contains(fileTypeName)
		}
		.flatMap { (_, fileType) in
			fileType.unpackedAndPacked()
		}
	
	if let fileType = fileTypes.first(where: name.hasExtension) {
		return try fileType.init(data, configuration: configuration)
	}
	
	let dataCopy = Datastream(data) // copy to not modify
	// most ff file types have 3-byte magic bytes with a null terminator, but
	// some (SDAT, ffc DMSK) have 4-bytes with no terminator. this won't match
	// a file if it's exactly 3 bytes long, but that should be ok... right?
	if let magicBytes = try? dataCopy.read(String.self, length: 4),
		magicBytes.isNotEmpty,
		let fileType = fileTypes.first(where: { $0.magicBytes == magicBytes })
	{
		return try fileType.init(data, configuration: configuration)
	}
	
	return nil
}

fileprivate extension ProprietaryFileData {
	static func unpackedAndPacked() -> [any ProprietaryFileData.Type] {
		[Unpacked.self, Packed.self]
	}
}

fileprivate extension String {
	func hasExtension(of fileType: any ProprietaryFileData.Type) -> Bool {
		fileType.fileExtension.isNotEmpty && hasSuffix(fileType.fileExtension)
	}
}
