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
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> FILETYPE.Unpacked {
		FILETYPE.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: FILETYPE.Unpacked, configuration: Configuration) {
		todo()
	}
}

// MARK: unpacked
extension FILETYPE.Unpacked: ProprietaryFileData {
	static let fileExtension = ".FILE_EXTENSION.json"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> FILETYPE.Packed {
		FILETYPE.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: FILETYPE.Packed, configuration: Configuration) {
		todo()
	}
}
