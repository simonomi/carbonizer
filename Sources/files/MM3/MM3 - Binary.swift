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
		let table1Name = try data.readCString()
		
		data.seek(to: tableNameOffset2)
		let table2Name = try data.readCString()
		
		data.seek(to: tableNameOffset3)
		let table3Name = try data.readCString()
		
		tableNames = (table1Name, table2Name, table3Name)
	}
}

extension Data {
	init(from mm3File: MM3File) throws {
		let data = Datawriter()
		
		try data.write("MM3\0")
		
		let table1NameOffset = UInt32(0x1c)
		
		let table1NameLength = UInt32(mm3File.tableNames.0.count) + 1
		var table2NameOffset = table1NameOffset + table1NameLength
		if !table2NameOffset.isMultiple(of: 4) {
			table2NameOffset = table2NameOffset + 4 - (table2NameOffset % 4)
		}
		
		let table2NameLength = UInt32(mm3File.tableNames.1.count) + 1
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
		
		try data.writeCString(mm3File.tableNames.0)
		
		data.seek(to: table2NameOffset)
		try data.writeCString(mm3File.tableNames.1)
		
		data.seek(to: table3NameOffset)
		try data.writeCString(mm3File.tableNames.2)
		
		self = data.data
	}
}
