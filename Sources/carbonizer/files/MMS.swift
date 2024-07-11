import BinaryParser

struct MMS: Writeable {
	var unknown1: UInt32
	var unknown2: UInt32
	var colorPaletteType: SpritePalette.ColorPaletteType
	var unknown4: UInt32
	var unknown5: UInt32
	
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
		var unknown4: UInt32 // 0...12, 14...16
		var unknown5: UInt32 = 60 // header size??
		
		var animationIndexCount: UInt32
		var animationIndexOffset: UInt32 // NOT always 60
		var animationNameOffset: UInt32
		
		var colorPaletteIndexCount: UInt32
		var colorPaletteIndexOffset: UInt32
		var colorPaletteNameOffset: UInt32
		
		var bitmapIndexCount: UInt32
		var bitmapIndexOffset: UInt32
		var bitmapNameOffset: UInt32
		
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
		unknown2 = packed.unknown2
		colorPaletteType = packed.colorPaletteType
		unknown4 = packed.unknown4
		unknown5 = packed.unknown5
		
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
	init(_ mpm: MMS) {
		fatalError("TODO")
	}
}

// MARK: unpacked
extension MMS: Codable {
	// TODO: custom codingkeys?
}

extension MMS.TableEntry: Codable {
	// TODO: custom codingkeys?
}
