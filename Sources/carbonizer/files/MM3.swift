//
//  MM3.swift
//
//
//  Created by alice on 2023-11-25.
//

import BinaryParser

struct MM3: Codable {
	var entry1: TableEntry
	var entry2: TableEntry
	var entry3: TableEntry
	
	struct TableEntry: Codable {
		var index: UInt32
		var tableName: String
	}
	
	@BinaryConvertible
	struct Binary {
		var magicBytes = "MM3"
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
		@Offset(givenBy: \Self.tableFileName3Offset)
		var tableFileName3: String
	}
}

// MARK: packed
extension MM3: FileData {
	init(packed: Binary) {
		entry1 = TableEntry(index: packed.index1, tableName: packed.tableFileName1)
		entry2 = TableEntry(index: packed.index2, tableName: packed.tableFileName2)
		entry3 = TableEntry(index: packed.index3, tableName: packed.tableFileName3)
	}
}

extension MM3.Binary: InitFrom {
	init(_ mm3: MM3) {
		index1 = mm3.entry1.index
		index2 = mm3.entry2.index
		index3 = mm3.entry3.index
		
		tableFileName1 = mm3.entry1.tableName
		tableFileName2 = mm3.entry2.tableName
		tableFileName3 = mm3.entry3.tableName
		
		// TODO: verify this
		tableFileName1Offset = 0x1C
		tableFileName2Offset = tableFileName1Offset + UInt32(tableFileName2.utf8CString.count)
		tableFileName3Offset = tableFileName2Offset + UInt32(tableFileName3.utf8CString.count)
	}
}

// MARK: unpacked
extension MM3 {
	enum CodingKeys: String, CodingKey {
		case entry1 = "entry 1"
		case entry2 = "entry 2"
		case entry3 = "entry 3"
	}
}

extension MM3.TableEntry {
	enum CodingKeys: String, CodingKey {
		case index =     "index"
		case tableName = "table name"
	}
}
