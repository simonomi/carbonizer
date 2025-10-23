import BinaryParser

enum DTX {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "DTX"
		var stringCount: UInt32
		var indicesOffset: UInt32 = 0xC
		@Count(givenBy: \Self.stringCount)
		@Offset(givenBy: \Self.indicesOffset)
		var indices: [UInt32]
		@Offsets(givenBy: \Self.indices)
		var strings: [String]
		
		@FourByteAlign
		var fourByteAlign: ()
	}
	
	struct Unpacked {
		var strings: [String]
	}
}

// MARK: packed
extension DTX.Packed: ProprietaryFileData {
	static let fileExtension = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> DTX.Unpacked {
		DTX.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: DTX.Unpacked, configuration: Configuration) {
		stringCount = UInt32(unpacked.strings.count)

		indices = makeOffsets(
			start: indicesOffset + stringCount * 4,
			sizes: unpacked.strings
				.map(\.utf8CString.count)
				.map(UInt32.init)
		)
		
		strings = unpacked.strings
	}
}

// MARK: unpacked
extension DTX.Unpacked: ProprietaryFileData {
	static let fileExtension = ".dtx.json"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> DTX.Packed {
		DTX.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: DTX.Packed, configuration: Configuration) {
		strings = packed.strings
	}
}

// MARK: unpacked codable
extension DTX.Unpacked: Codable {
	init(from decoder: Decoder) throws {
		strings = try [String](from: decoder)
	}
	
	func encode(to encoder: Encoder) throws {
		try strings.encode(to: encoder)
	}
}
