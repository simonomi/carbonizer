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
		"SHP": SHP.Unpacked.self
	]
	
	let fileTypes: [any ProprietaryFileData.Type] = allFileTypes
		.filter { (fileTypeName, _) in
			configuration.fileTypes.contains(fileTypeName)
		}
		.flatMap { (_, fileType) in
			fileType.unpackedAndPacked()
		}
	
	if let fileType = fileTypes.first(where: name.hasExtension) {
		return try fileType.init(data, configuration: configuration) as any ProprietaryFileData
	}
	
	let marker = data.placeMarker()
	let magicBytes = try? data.read(String.self, exactLength: 3) // in ffc, donate_mask_defs has DMSK
	data.jump(to: marker)
	
	if let fileType = fileTypes.first(where: { $0.magicBytes == magicBytes }) {
		return try fileType.init(data, configuration: configuration) as any ProprietaryFileData
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
