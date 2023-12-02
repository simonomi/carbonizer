//
//  MPM.swift
//
//
//  Created by alice on 2023-11-25.
//

import BinaryParser

struct MPM: Codable {
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
	
	struct TableEntry: Codable {
		var index: UInt32
		var tableName: String
	}
	
	@BinaryConvertible
	struct Binary {
		var magicBytes = "MPM"
		var unknown1: UInt32
		var unknown2: UInt32
		var unknown3: UInt32
		var width: UInt32
		var height: UInt32
		var unknown4: UInt32
		var unknown5: UInt32
		var unknown6: UInt32
		var index1: UInt32
		var tableFileName1Offset: UInt32
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
}

// MARK: packed
extension MPM: FileData {
	init(packed: Binary) {
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

extension MPM.Binary: InitFrom {
	init(_ mpm: MPM) {
		unknown1 = mpm.unknown1
		unknown2 = mpm.unknown2
		unknown3 = mpm.unknown3
		
		width = mpm.width
		height = mpm.height
		
		unknown4 = mpm.unknown4
		unknown5 = mpm.unknown5
		unknown6 = mpm.unknown6
		
		index1 = mpm.entry1.index
		index2 = mpm.entry2.index
		index3 = mpm.entry3?.index ?? 0
		
		tableFileName1 = mpm.entry1.tableName
		tableFileName2 = mpm.entry2.tableName
		tableFileName3 = mpm.entry3?.tableName
		
		// TODO: verify this
		tableFileName1Offset = 0x1C
		tableFileName2Offset = tableFileName1Offset + UInt32(tableFileName2.utf8CString.count)
		tableFileName3Offset = tableFileName3.map { [tableFileName2Offset] in
			tableFileName2Offset + UInt32($0.utf8CString.count)
		} ?? 0
	}
}

// MARK: unpacked
extension MPM {
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

extension MPM.TableEntry {
	enum CodingKeys: String, CodingKey {
		case index =     "index"
		case tableName = "table name"
	}
}
