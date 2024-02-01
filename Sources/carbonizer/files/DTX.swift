import BinaryParser

struct DTX: Codable, Writeable {
	var strings: [String]
	
	@BinaryConvertible
	struct Binary: Writeable {
		var magicBytes = "DTX"
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
extension DTX: FileData {
	static var packedFileExtension = ""
	static var unpackedFileExtension = "dtx.json"
	
	init(packed: Binary) {
		strings = packed.strings
	}
}

extension DTX.Binary: InitFrom {
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
extension DTX {
	init(from decoder: Decoder) throws {
		strings = try [String](from: decoder)
	}
	
	func encode(to encoder: Encoder) throws {
		try strings.encode(to: encoder)
	}
}
