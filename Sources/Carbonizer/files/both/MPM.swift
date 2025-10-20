import BinaryParser

enum MPM {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "MPM"
		var unknown1: UInt32
		var unknown2: UInt32
		var unknown3: UInt32
		
		var width: UInt32
		var height: UInt32
		
		var colorCountDividedBy16: UInt32
		var unknown5: UInt32
		var unknown6: UInt32
		
		var paletteIndex: UInt32
		var paletteTableNameOffset: UInt32 = 0x3C
		
		var bitmapIndex: UInt32
		var bitmapTableNameOffset: UInt32
		
		var bgMapIndex: UInt32
		var bgMapTableNameOffset: UInt32
		
		@Offset(givenBy: \Self.paletteTableNameOffset)
		var paletteTableName: String
		
		@Offset(givenBy: \Self.bitmapTableNameOffset)
		var bitmapTableName: String
		
		@If(\Self.bgMapTableNameOffset, is: .notEqualTo(0))
		@Offset(givenBy: \Self.bgMapTableNameOffset)
		var bgMapTableName: String?
		
		@FourByteAlign
		var fourByteAlign: ()
	}
	
	struct Unpacked: Codable {
		// always either 030, 404, or 508
		// 030 means 8-bit texture with no bgmaps
		var unknown1: UInt32
		var unknown2: UInt32
		var unknown3: UInt32
		
		var width: UInt32
		var height: UInt32
		
		var colorCount: UInt32
		var unknown5: UInt32 // 2 u16s ?
		var unknown6: UInt32
		
		var palette: TableEntry
		var bitmap: TableEntry
		var bgMap: TableEntry?
		
		struct TableEntry: Codable {
			var index: UInt32
			var tableName: String
		}
	}
}

// MARK: packed
extension MPM.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> MPM.Unpacked {
		MPM.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: MPM.Unpacked, configuration: Configuration) {
		unknown1 = unpacked.unknown1
		unknown2 = unpacked.unknown2
		unknown3 = unpacked.unknown3
		
		width = unpacked.width
		height = unpacked.height
		
		colorCountDividedBy16 = unpacked.colorCount / 16
		unknown5 = unpacked.unknown5
		unknown6 = unpacked.unknown6
		
		paletteIndex = unpacked.palette.index
		bitmapIndex = unpacked.bitmap.index
		bgMapIndex = unpacked.bgMap?.index ?? 0
		
		paletteTableName = unpacked.palette.tableName
		bitmapTableName = unpacked.bitmap.tableName
		bgMapTableName = unpacked.bgMap?.tableName
		
		bitmapTableNameOffset = paletteTableNameOffset + UInt32(bitmapTableName.utf8CString.count.roundedUpToTheNearest(4))
		bgMapTableNameOffset = bgMapTableName.map { [bitmapTableNameOffset] in
			bitmapTableNameOffset + UInt32($0.utf8CString.count.roundedUpToTheNearest(4))
		} ?? 0
	}
}

// MARK: unpacked
extension MPM.Unpacked: ProprietaryFileData {
	static let fileExtension = ".mpm.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: Configuration) -> MPM.Packed {
		MPM.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: MPM.Packed, configuration: Configuration) {
		unknown1 = packed.unknown1
		unknown2 = packed.unknown2
		unknown3 = packed.unknown3
		
		width = packed.width
		height = packed.height
		
		colorCount = packed.colorCountDividedBy16 * 16
		unknown5 = packed.unknown5
		unknown6 = packed.unknown6
		
		palette = TableEntry(index: packed.paletteIndex, tableName: packed.paletteTableName)
		bitmap = TableEntry(index: packed.bitmapIndex, tableName: packed.bitmapTableName)
		bgMap = packed.bgMapTableName.map {
			TableEntry(index: packed.bgMapIndex, tableName: $0)
		}
	}
}
