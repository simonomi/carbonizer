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
		var unknown4: UInt32
		var unknown5: UInt32
		var unknown6: UInt32
		var index1: UInt32
		var tableFileName1Offset: UInt32 = 0x3C
		var index2: UInt32
		var tableFileName2Offset: UInt32
		var index3: UInt32
		var tableFileName3Offset: UInt32
		@Offset(givenBy: \Self.tableFileName1Offset)
		var tableFileName1: String
		@Offset(givenBy: \Self.tableFileName2Offset)
		var tableFileName2: String
		@If(\Self.tableFileName3Offset, is: .notEqualTo(0))
		@Offset(givenBy: \Self.tableFileName3Offset)
		var tableFileName3: String?
	}
	
	struct Unpacked {
		// always either 030, 404, or 508
		// 030 means 8-bit texture with no bgmaps
		var unknown1: UInt32
		var unknown2: UInt32
		var unknown3: UInt32
		
		var width: UInt32
		var height: UInt32
		
		var unknown4: UInt32
		var unknown5: UInt32
		var unknown6: UInt32
		
		var entry1: TableEntry
		var entry2: TableEntry
		var entry3: TableEntry?
		
		struct TableEntry {
			var index: UInt32
			var tableName: String
		}
	}
}

// MARK: packed
extension MPM.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> MPM.Unpacked {
		MPM.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: MPM.Unpacked, configuration: CarbonizerConfiguration) {
		unknown1 = unpacked.unknown1
		unknown2 = unpacked.unknown2
		unknown3 = unpacked.unknown3
		
		width = unpacked.width
		height = unpacked.height
		
		unknown4 = unpacked.unknown4
		unknown5 = unpacked.unknown5
		unknown6 = unpacked.unknown6
		
		index1 = unpacked.entry1.index
		index2 = unpacked.entry2.index
		index3 = unpacked.entry3?.index ?? 0
		
		tableFileName1 = unpacked.entry1.tableName
		tableFileName2 = unpacked.entry2.tableName
		tableFileName3 = unpacked.entry3?.tableName
		
		tableFileName2Offset = tableFileName1Offset + UInt32(tableFileName2.utf8CString.count)
		tableFileName3Offset = tableFileName3.map { [tableFileName2Offset] in
			tableFileName2Offset + UInt32($0.utf8CString.count)
		} ?? 0
	}
}

// MARK: unpacked
extension MPM.Unpacked: ProprietaryFileData {
	static let fileExtension = ".mpm.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> MPM.Packed {
		MPM.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: MPM.Packed, configuration: CarbonizerConfiguration) {
		unknown1 = packed.unknown1
		unknown2 = packed.unknown2
		unknown3 = packed.unknown3
		
		width = packed.width
		height = packed.height
		
		unknown4 = packed.unknown4
		unknown5 = packed.unknown5
		unknown6 = packed.unknown6
		
		entry1 = TableEntry(index: packed.index1, tableName: packed.tableFileName1)
		entry2 = TableEntry(index: packed.index2, tableName: packed.tableFileName2)
		entry3 = packed.tableFileName3.map {
			TableEntry(index: packed.index3, tableName: $0)
		}
	}
}

// MARK: unpacked codable
extension MPM.Unpacked: Codable {
	enum CodingKeys: String, CodingKey {
		case unknown1 = "unknown 1"
		case unknown2 = "unknown 2"
		case unknown3 = "unknown 3"
		
		case width =  "width"
		case height = "height"
		
		case unknown4 = "unknown 4"
		case unknown5 = "unknown 5"
		case unknown6 = "unknown 6"
		
		case entry1 = "entry 1"
		case entry2 = "entry 2"
		case entry3 = "entry 3"
	}
}

extension MPM.Unpacked.TableEntry: Codable {
	enum CodingKeys: String, CodingKey {
		case index =     "index"
		case tableName = "table name"
	}
}
