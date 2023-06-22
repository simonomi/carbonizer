//
//  MM3 - Binary.swift
//
//
//  Created by simon pellerin on 2023-06-21.
//

import Foundation

extension MM3File {
	init(named name: String, from inputData: Data) throws {
		self.name = name
		
		let data = Datastream(inputData)
		
		data.seek(to: 4)
		
		let index1 = try data.read(UInt32.self)
		let tableNameOffset1 = try data.read(UInt32.self)
		let index2 = try data.read(UInt32.self)
		let tableNameOffset2 = try data.read(UInt32.self)
		let index3 = try data.read(UInt32.self)
		let tableNameOffset3 = try data.read(UInt32.self)
		
		indexes = (index1, index2, index3)
		
		data.seek(to: tableNameOffset1)
		
		let table1NameLength = tableNameOffset2 - tableNameOffset1
		let table1Name = try data.readString(length: table1NameLength).replacingOccurrences(of: "\0", with: "")
		
		let table2NameLength = tableNameOffset3 - tableNameOffset2
		let table2Name = try data.readString(length: table2NameLength).replacingOccurrences(of: "\0", with: "")
		
		let table3NameLength = UInt32(data.data.count) - tableNameOffset3
		let table3Name = try data.readString(length: table3NameLength).replacingOccurrences(of: "\0", with: "")
		
		tableNames = (table1Name, table2Name, table3Name)
	}
}

extension Data {
	init(from mm3File: MM3File) throws {
		let data = Datawriter()
		
		try data.write("DMG\0")
		
		let table1NameLength = UInt32(mm3File.tableNames.0.count)
		let table2NameLength = UInt32(mm3File.tableNames.1.count)
		
		let table1NameOffset = UInt32(0x1c)
		
		var table2NameOffset = table1NameOffset + table1NameLength
		if !table2NameOffset.isMultiple(of: 4) {
			table2NameOffset = table2NameOffset + 4 - (table2NameOffset % 4)
		}
		
		var table3NameOffset = table2NameOffset + table2NameLength
		if !table3NameOffset.isMultiple(of: 4) {
			table3NameOffset = table3NameOffset + 4 - (table3NameOffset % 4)
		}
		
		data.write(mm3File.indexes.0)
		data.write(table1NameOffset)
		data.write(mm3File.indexes.1)
		data.write(table2NameOffset)
		data.write(mm3File.indexes.2)
		data.write(table3NameOffset)
		
		try data.write(mm3File.tableNames.0)
		
		data.seek(to: table2NameOffset)
		try data.write(mm3File.tableNames.1)
		
		data.seek(to: table3NameOffset)
		try data.write(mm3File.tableNames.2)
		
		self = data.data
	}
}
