import BinaryParser

// $f - finish current dialogue box

enum DMG {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "DMG.Unpacked"
		var stringCount: UInt32
		var indicesOffset: UInt32 = 0xC
		@Count(givenBy: \Self.stringCount)
		@Offset(givenBy: \Self.indicesOffset)
		var indices: [UInt32]
		@Offsets(givenBy: \Self.indices)
		var strings: [DMGString]
		
		@BinaryConvertible
		struct DMGString {
			var index: UInt32
			var stringOffset: UInt32 = 0x8
			@Offset(givenBy: \Self.stringOffset)
			var string: String
		}
	}
	
	struct Unpacked {
		var strings: [DMGString]
		
		struct DMGString: Codable {
			var index: UInt32
			var string: String
		}
	}
}

// MARK: packed
extension DMG.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> DMG.Unpacked {
		DMG.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: DMG.Unpacked, configuration: CarbonizerConfiguration) {
		stringCount = UInt32(unpacked.strings.count)
		
		indices = makeOffsets(
			start: indicesOffset + stringCount * 4,
			sizes: unpacked.strings
				.map(\.string.utf8CString.count)
				.map { $0 + 8 }
				.map(UInt32.init),
			alignedTo: 4
		)
		
		strings = unpacked.strings.map(DMG.Packed.DMGString.init)
	}
}

extension DMG.Packed.DMGString {
	init(_ unpacked: DMG.Unpacked.DMGString) {
		index = unpacked.index
		string = unpacked.string
	}
}

// MARK: unpacked
extension DMG.Unpacked: ProprietaryFileData {
	static let fileExtension = ".dmg.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> DMG.Packed {
		DMG.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: DMG.Packed, configuration: CarbonizerConfiguration) {
		strings = packed.strings.map(DMGString.init)
	}
}

extension DMG.Unpacked.DMGString {
	init(_ packed: DMG.Packed.DMGString) {
		index = packed.index
		string = packed.string
	}
}

// MARK: unpacked codable
extension DMG.Unpacked: Codable {
	init(from decoder: Decoder) throws {
		strings = try [DMGString](from: decoder)
	}
	
	func encode(to encoder: Encoder) throws {
		try strings.encode(to: encoder)
	}
}
