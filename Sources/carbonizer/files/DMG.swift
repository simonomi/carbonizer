import BinaryParser

// $f - finish current dialogue box

struct DMG {
	var strings: [DMGString]
	
	struct DMGString: Codable {
		var index: UInt32
		var string: String
	}
	
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "DMG"
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
}

// MARK: packed
extension DMG: ProprietaryFileData, BinaryConvertible {
	static let fileExtension = ".dmg.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	init(_ binary: Binary, configuration: CarbonizerConfiguration) {
		strings = binary.strings.map(DMGString.init)
	}
}

extension DMG.DMGString {
	init(_ dmgStringBinary: DMG.Binary.DMGString) {
		index = dmgStringBinary.index
		string = dmgStringBinary.string
	}
}

extension DMG.Binary: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	init(_ dmg: DMG, configuration: CarbonizerConfiguration) {
		stringCount = UInt32(dmg.strings.count)
		
		indices = makeOffsets(
			start: indicesOffset + stringCount * 4,
			sizes: dmg.strings
				.map(\.string.utf8CString.count)
				.map { $0 + 8 }
				.map(UInt32.init),
			alignedTo: 4
		)
		
		strings = dmg.strings.map(DMG.Binary.DMGString.init)
	}
}

extension DMG.Binary.DMGString {
	init(_ dmgString: DMG.DMGString) {
		index = dmgString.index
		string = dmgString.string
	}
}


// MARK: unpacked
extension DMG: Codable {
	init(from decoder: Decoder) throws {
		strings = try [DMGString](from: decoder)
	}
	
	func encode(to encoder: Encoder) throws {
		try strings.encode(to: encoder)
	}
}
