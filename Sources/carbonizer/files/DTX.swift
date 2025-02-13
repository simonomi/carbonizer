import BinaryParser

struct DTX {
	var strings: [String]
	
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "DTX"
		var stringCount: UInt32
		var indicesOffset: UInt32 = 0xC
		@Count(givenBy: \Self.stringCount)
		@Offset(givenBy: \Self.indicesOffset)
		var indices: [UInt32]
		@Offsets(givenBy: \Self.indices)
		var strings: [String]
	}
}

// MARK: packed
extension DTX: ProprietaryFileData {
	static let fileExtension = ".dtx.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	init(_ binary: Binary, configuration: CarbonizerConfiguration) {
		strings = binary.strings
	}
}

extension DTX.Binary: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	init(_ dtx: DTX, configuration: CarbonizerConfiguration) {
		stringCount = UInt32(dtx.strings.count)

		indices = makeOffsets(
			start: indicesOffset + stringCount * 4,
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
