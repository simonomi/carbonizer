import BinaryParser

// replace FILETYPE with the magic bytes
// and FILE_EXTENSION the same but lowercase

enum FILETYPE {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "FILETYPE"
		
		// data
	}
	
	struct Unpacked: Codable {}
}

// MARK: packed
extension FILETYPE.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> FILETYPE.Unpacked {
		FILETYPE.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: FILETYPE.Unpacked, configuration: CarbonizerConfiguration) {
		todo()
	}
}

// MARK: unpacked
extension FILETYPE.Unpacked: ProprietaryFileData {
	static let fileExtension = ".FILE_EXTENSION.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> FILETYPE.Packed {
		FILETYPE.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: FILETYPE.Packed, configuration: CarbonizerConfiguration) {
		todo()
	}
}
