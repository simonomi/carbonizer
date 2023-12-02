//
//  DMG.swift
//
//
//  Created by alice on 2023-11-25.
//

import BinaryParser

struct DMG: Codable {
	var strings: [DMGString]
	
	struct DMGString: Codable {
		var index: UInt32
		var string: String
	}
	
	@BinaryConvertible
	struct Binary {
		var magicBytes = "DMG"
		var stringCount: UInt32
		var indexesOffset: UInt32 = 0xC
		@Offset(givenBy: \Self.indexesOffset)
		@Count(givenBy: \Self.stringCount)
		var indexes: [UInt32]
		@Offsets(givenBy: \Self.indexes)
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
extension DMG: FileData {
	init(packed: Binary) {
		strings = packed.strings.map(DMGString.init)
	}
}

extension DMG.DMGString {
	init(_ dmgStringBinary: DMG.Binary.DMGString) {
		index = dmgStringBinary.index
		string = dmgStringBinary.string
	}
}

extension DMG.Binary: InitFrom {
	init(_ dmg: DMG) {
		stringCount = UInt32(dmg.strings.count)
		
		indexes = createOffsets(
			start: indexesOffset + stringCount * 4,
			sizes: dmg.strings
				.map(\.string.utf8CString.count)
				.map(UInt32.init)
		)
		
		strings = dmg.strings.map(DMG.Binary.DMGString.init)
	}
}
