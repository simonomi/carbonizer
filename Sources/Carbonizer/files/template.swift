import BinaryParser

// replace FILETYPE with the magic bytes
// and FILETYPE_LOWERCASE the same but lowercase

struct FILETYPE {
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "FILETYPE"
		
		// data
	}
}

extension FILETYPE: ProprietaryFileData, BinaryConvertible, Codable {
	static let fileExtension = ".FILETYPE_LOWERCASE.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	init(_ binary: Binary, configuration: CarbonizerConfiguration) {
		todo()
	}
}

extension FILETYPE.Binary: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	init(_ FILETYPE_LOWERCASE: FILETYPE, configuration: CarbonizerConfiguration) {
		todo()
	}
}

