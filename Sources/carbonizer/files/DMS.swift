import BinaryParser

struct DMS {
	var value: UInt32
	
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "DMS"
		var value: UInt32
	}
}

// MARK: packed
extension DMS: ProprietaryFileData {
	static let fileExtension = "dms.json"
	static let packedStatus: PackedStatus = .unpacked
	
	init(_ binary: Binary) {
		value = binary.value
	}
}

extension DMS.Binary: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	init(_ dms: DMS) {
		value = dms.value
	}
}

// MARK: unpacked
extension DMS: Codable {
	init(from decoder: Decoder) throws {
		value = try UInt32(from: decoder)
	}
	
	func encode(to encoder: Encoder) throws {
		try value.encode(to: encoder)
	}
}
