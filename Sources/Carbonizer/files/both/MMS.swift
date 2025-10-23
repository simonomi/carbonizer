import BinaryParser

enum MMS {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "MMS"
		var unknown1: UInt32 // 0, 1, 2, 3, 4, 7, 8, 12, 15, 21, 31, 63, 84, 127, 131, 255, 296, 8064
		var unknown2: UInt32 = 0
		
		var colorPaletteType: ColorPaletteType
		@Padding(bytes: 3)
		
		var unknownsCount: UInt32 // 0...12, 14...16
		var unknownsOffset: UInt32 = 0x3C
		
		var animationIndexCount: UInt32
		var animationIndexOffset: UInt32
		var animationTableNameOffset: UInt32
		
		var paletteIndexCount: UInt32
		var paletteIndexOffset: UInt32
		var paletteTableNameOffset: UInt32
		
		var bitmapIndexCount: UInt32
		var bitmapIndexOffset: UInt32
		var bitmapTableNameOffset: UInt32
		
		@Count(givenBy: \Self.unknownsCount, .times(4))
		@Offset(givenBy: \Self.unknownsOffset)
		var unknowns: [UInt32]
		
		@Count(givenBy: \Self.animationIndexCount)
		@Offset(givenBy: \Self.animationIndexOffset)
		var animationIndices: [UInt32]
		@Offset(givenBy: \Self.animationTableNameOffset)
		var animationTableName: String
		
		@Count(givenBy: \Self.paletteIndexCount)
		@Offset(givenBy: \Self.paletteIndexOffset)
		var paletteIndices: [UInt32]
		@Offset(givenBy: \Self.paletteTableNameOffset)
		var paletteTableName: String
		
		@Count(givenBy: \Self.bitmapIndexCount)
		@Offset(givenBy: \Self.bitmapIndexOffset)
		var bitmapIndices: [UInt32]
		@Offset(givenBy: \Self.bitmapTableNameOffset)
		var bitmapTableName: String
		
		@FourByteAlign
		var fourByteAlign: ()
		
		enum ColorPaletteType: UInt8, RawRepresentable {
			case sixteenColors, twoFiftySixColors
		}
	}
	
	struct Unpacked: Codable {
		var unknown1: UInt32
		var colorPaletteType: ColorPaletteType
		
		var unknowns: [UInt32]
		
		// unknowns notes:
		// - always a power of 2 (0 1 2 4 8 16 32 64)
		// - either the first two, last two, or all 4 bytes are 0
		// - the first of the two non-zero bytes is always 1
		// - commonly smthn like 1 64 0 0 1 32 0 0
		
		var animations: TableEntry
		var palettes: TableEntry
		var bitmaps: TableEntry
		
		enum ColorPaletteType: String, Codable {
			case sixteenColors, twoFiftySixColors
		}
		
		struct TableEntry: Codable {
			var indices: [UInt32]
			var tableName: String
		}
	}
}

// MARK: packed
extension MMS.Packed: ProprietaryFileData {
	static let fileExtension = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> MMS.Unpacked {
		MMS.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: MMS.Unpacked, configuration: Configuration) {
		unknown1 = unpacked.unknown1
		
		colorPaletteType = ColorPaletteType(unpacked.colorPaletteType)
		
		unknowns = unpacked.unknowns
		unknownsCount = UInt32(unknowns.count) / 4
		
		animationIndices = unpacked.animations.indices
		paletteIndices = unpacked.palettes.indices
		bitmapIndices = unpacked.bitmaps.indices
		
		animationIndexCount = UInt32(animationIndices.count)
		paletteIndexCount = UInt32(paletteIndices.count)
		bitmapIndexCount = UInt32(bitmapIndices.count)
		
		animationTableName = unpacked.animations.tableName
		paletteTableName = unpacked.palettes.tableName
		bitmapTableName = unpacked.bitmaps.tableName
		
		animationIndexOffset = unknownsOffset + unknownsCount * 16
		animationTableNameOffset = animationIndexOffset + animationIndexCount * 4
		
		paletteIndexOffset = animationTableNameOffset + UInt32(animationTableName.utf8CString.count).roundedUpToTheNearest(4)
		paletteTableNameOffset = paletteIndexOffset + paletteIndexCount * 4
		
		bitmapIndexOffset = paletteTableNameOffset + UInt32(paletteTableName.utf8CString.count).roundedUpToTheNearest(4)
		bitmapTableNameOffset = bitmapIndexOffset + bitmapIndexCount * 4
	}
}

extension MMS.Packed.ColorPaletteType {
	init(_ unpacked: MMS.Unpacked.ColorPaletteType) {
		self = switch unpacked {
			case .sixteenColors: .sixteenColors
			case .twoFiftySixColors: .twoFiftySixColors
		}
	}
}

// MARK: unpacked
extension MMS.Unpacked: ProprietaryFileData {
	static let fileExtension = ".mms.json"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> MMS.Packed {
		MMS.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: MMS.Packed, configuration: Configuration) {
		unknown1 = packed.unknown1
		
		colorPaletteType = ColorPaletteType(packed.colorPaletteType)
		
		unknowns = packed.unknowns
		
//		for index in stride(from: 0, to: unknowns.count, by: 4) {
//			let one = unknowns[index]
//			let two = unknowns[index + 1]
//			let three = unknowns[index + 2]
//			let four = unknowns[index + 3]
//			
//			print(two, four)
//		}
		
//		print(unknowns.map(hex)/*.map { $0.padded(toLength: 2, with: "0") }*/.joined(separator: " "))
		
		animations = TableEntry(
			indices: packed.animationIndices,
			tableName: packed.animationTableName
		)
		palettes = TableEntry(
			indices: packed.paletteIndices,
			tableName: packed.paletteTableName
		)
		bitmaps = TableEntry(
			indices: packed.bitmapIndices,
			tableName: packed.bitmapTableName
		)
	}
}

extension MMS.Unpacked.ColorPaletteType {
	init(_ packed: MMS.Packed.ColorPaletteType) {
		self = switch packed {
			case .sixteenColors: .sixteenColors
			case .twoFiftySixColors: .twoFiftySixColors
		}
	}
}
