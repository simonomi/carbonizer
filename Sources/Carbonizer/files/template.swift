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
	
	func packed(configuration: Carbonizer.Configuration) -> Self { self }
	
	func unpacked(configuration: Carbonizer.Configuration) -> FILETYPE.Unpacked {
		FILETYPE.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: FILETYPE.Unpacked, configuration: Carbonizer.Configuration) {
		todo()
	}
}

// MARK: unpacked
extension FILETYPE.Unpacked: ProprietaryFileData {
	static let fileExtension = ".FILE_EXTENSION.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: Carbonizer.Configuration) -> FILETYPE.Packed {
		FILETYPE.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Carbonizer.Configuration) -> Self { self }
	
	fileprivate init(_ packed: FILETYPE.Packed, configuration: Carbonizer.Configuration) {
		todo()
	}
}
