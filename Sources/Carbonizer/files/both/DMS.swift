import BinaryParser

enum DMS {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "DMS"
		var value: UInt32
	}
	
	struct Unpacked {
		var value: UInt32
	}
}

// MARK: packed
extension DMS.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> DMS.Unpacked {
		DMS.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: DMS.Unpacked, configuration: CarbonizerConfiguration) {
		value = unpacked.value
	}
}

// MARK: unpacked
extension DMS.Unpacked: ProprietaryFileData {
	static let fileExtension = ".dms.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> DMS.Packed {
		DMS.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: DMS.Packed, configuration: CarbonizerConfiguration) {
		value = packed.value
	}
}

// MARK: unpacked codable
extension DMS.Unpacked: Codable {
	init(from decoder: Decoder) throws {
		value = try UInt32(from: decoder)
	}
	
	func encode(to encoder: Encoder) throws {
		try value.encode(to: encoder)
	}
}
