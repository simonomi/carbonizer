import BinaryParser

struct MMS: Writeable {
	var unknown1: UInt32
	var colorPaletteType: SpritePalette.ColorPaletteType
	
	var unknowns: [UInt64]
	
	var animation: TableEntry
	var colorPalette: TableEntry
	var bitmap: TableEntry
	
	struct TableEntry {
		var indices: [UInt32]
		var tableName: String
	}
	
	@BinaryConvertible
	struct Binary: Writeable {
		var magicBytes = "MMS"
		var unknown1: UInt32 // 0, 1, 2, 3, 4, 7, 8, 12, 15, 21, 31, 63, 84, 127, 131, 255, 296, 8064
		var unknown2: UInt32 = 0
		
		var colorPaletteType: SpritePalette.ColorPaletteType
		@Padding(bytes: 3)
		
		var unknownsCount: UInt32 // 0...12, 14...16
		var unknownsOffset: UInt32 = 60
		
		var animationIndexCount: UInt32
		var animationIndexOffset: UInt32
		var animationNameOffset: UInt32
		
		var colorPaletteIndexCount: UInt32
		var colorPaletteIndexOffset: UInt32
		var colorPaletteNameOffset: UInt32
		
		var bitmapIndexCount: UInt32
		var bitmapIndexOffset: UInt32
		var bitmapNameOffset: UInt32
		
		@Count(givenBy: \Self.unknownsCount, .times(2))
		@Offset(givenBy: \Self.unknownsOffset)
		var unknowns: [UInt64]
		
		@Count(givenBy: \Self.animationIndexCount)
		@Offset(givenBy: \Self.animationIndexOffset)
		var animationIndices: [UInt32]
		@Offset(givenBy: \Self.animationNameOffset)
		var animationName: String
		
		@Count(givenBy: \Self.colorPaletteIndexCount)
		@Offset(givenBy: \Self.colorPaletteIndexOffset)
		var colorPaletteIndices: [UInt32]
		@Offset(givenBy: \Self.colorPaletteNameOffset)
		var colorPaletteName: String
		
		@Count(givenBy: \Self.bitmapIndexCount)
		@Offset(givenBy: \Self.bitmapIndexOffset)
		var bitmapIndices: [UInt32]
		@Offset(givenBy: \Self.bitmapNameOffset)
		var bitmapName: String
	}
}

// MARK: packed
extension MMS: FileData {
	static var packedFileExtension = "bin"
	static var unpackedFileExtension = "mms.json"
	
	init(packed: Binary) {
		unknown1 = packed.unknown1
		
		colorPaletteType = packed.colorPaletteType
		
		unknowns = packed.unknowns
		
		animation = TableEntry(
			indices: packed.animationIndices,
			tableName: packed.animationName
		)
		colorPalette = TableEntry(
			indices: packed.colorPaletteIndices,
			tableName: packed.colorPaletteName
		)
		bitmap = TableEntry(
			indices: packed.bitmapIndices,
			tableName: packed.bitmapName
		)
	}
}

extension MMS.Binary: InitFrom {
	init(_ mms: MMS) {
		unknown1 = mms.unknown1
		
		colorPaletteType = mms.colorPaletteType
		
		unknowns = mms.unknowns
		unknownsCount = UInt32(unknowns.count)
		
		animationIndices = mms.animation.indices
		colorPaletteIndices = mms.colorPalette.indices
		bitmapIndices = mms.bitmap.indices
		
		animationIndexCount = UInt32(animationIndices.count)
		colorPaletteIndexCount = UInt32(colorPaletteIndices.count)
		bitmapIndexCount = UInt32(bitmapIndices.count)
		
		animationName = mms.animation.tableName
		colorPaletteName = mms.colorPalette.tableName
		bitmapName = mms.bitmap.tableName
		
		animationIndexOffset = unknownsOffset + unknownsCount * 16
		animationNameOffset = animationIndexOffset + animationIndexCount * 4
		
		colorPaletteIndexOffset = animationNameOffset + UInt32(animationName.utf8CString.count)
		colorPaletteNameOffset = colorPaletteIndexOffset + colorPaletteIndexCount * 4
		
		bitmapIndexOffset = colorPaletteNameOffset + UInt32(colorPaletteName.utf8CString.count)
		bitmapNameOffset = bitmapIndexOffset + bitmapIndexCount * 4
	}
}

// MARK: unpacked
extension MMS: Codable {
	// TODO: custom codingkeys?
}

extension MMS.TableEntry: Codable {
	// TODO: custom codingkeys?
}
