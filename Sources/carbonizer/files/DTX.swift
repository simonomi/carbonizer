import BinaryParser

struct DTX {
	var strings: [String]
	
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "DTX"
		var stringCount: UInt32
		var indexesOffset: UInt32 = 0xC
		@Count(givenBy: \Self.stringCount)
		@Offset(givenBy: \Self.indexesOffset)
		var indexes: [UInt32]
		@Offsets(givenBy: \Self.indexes)
		var strings: [String]
	}
}

// MARK: packed
extension DTX: ProprietaryFileData {
	static let fileExtension = ".dtx.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	init(_ binary: Binary) {
		strings = binary.strings
	}
}

extension DTX.Binary: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	init(_ dtx: DTX) {
		stringCount = UInt32(dtx.strings.count)

		indexes = createOffsets(
			start: indexesOffset + stringCount * 4,
			sizes: dtx.strings
				.map(\.utf8CString.count)
				.map(UInt32.init)
		)
		
		strings = dtx.strings
	}
}

// MARK: unpacked
extension DTX: Codable {
	init(from decoder: Decoder) throws {
		strings = try [String](from: decoder)
	}
	
	func encode(to encoder: Encoder) throws {
		try strings.encode(to: encoder)
	}
}
