//
//  MPM - Binary.swift
//
//
//  Created by simon pellerin on 2023-06-21.
//

import Foundation

extension MPMFile {
	init(named name: String, from inputData: Data) throws {
		self.name = name
		
		let data = Datastream(inputData)
		
		data.seek(to: 4)
		
		unknown1 = try data.read(UInt32.self)
		unknown2 = try data.read(UInt32.self)
		unknown3 = try data.read(UInt32.self)
		
		width = try data.read(UInt32.self)
		height = try data.read(UInt32.self)
		
		unknown4 = try data.read(UInt32.self)
		unknown5 = try data.read(UInt32.self)
		unknown6 = try data.read(UInt32.self)
		
		let index1 = try data.read(UInt32.self)
		let tableNameOffset1 = try data.read(UInt32.self)
		let index2 = try data.read(UInt32.self)
		let tableNameOffset2 = try data.read(UInt32.self)
		
		var index3: UInt32? = try data.read(UInt32.self)
		if index3 == 0 {
			index3 = nil
		}
		
		var tableNameOffset3: UInt32? = try data.read(UInt32.self)
		if tableNameOffset3 == 0 {
			tableNameOffset3 = nil
		}
		
		indexes = (index1, index2, index3)
		
		data.seek(to: tableNameOffset1)
		let table1Name = try data.readCString()
		
		data.seek(to: tableNameOffset2)
		let table2Name = try data.readCString()
		
		let table3Name: String?
		if let tableNameOffset3 {
			data.seek(to: tableNameOffset3)
			table3Name = try data.readCString()
		} else {
			table3Name = nil
		}
		
		tableNames = (table1Name, table2Name, table3Name)
	}
}

extension Data {
	init(from mpmFile: MPMFile) throws {
		let data = Datawriter()
		
		try data.write("MPM\0")
		
		data.write(mpmFile.unknown1)
		data.write(mpmFile.unknown2)
		data.write(mpmFile.unknown3)
		
		data.write(mpmFile.width)
		data.write(mpmFile.height)
		
		data.write(mpmFile.unknown4)
		data.write(mpmFile.unknown5)
		data.write(mpmFile.unknown6)
		
		let table1NameOffset = UInt32(0x3c)
		
		let table1NameLength = UInt32(mpmFile.tableNames.0.count) + 1
		let table2NameOffset = (table1NameOffset + table1NameLength).toNearestMultiple(of: 4)
		
		let table2NameLength = UInt32(mpmFile.tableNames.1.count) + 1
		let table3NameOffset: UInt32
		if mpmFile.indexes.2 == nil {
			table3NameOffset = 0
		} else {
			table3NameOffset = (table2NameOffset + table2NameLength).toNearestMultiple(of: 4)
		}
		
		data.write(mpmFile.indexes.0)
		data.write(table1NameOffset)
		
		data.write(mpmFile.indexes.1)
		data.write(table2NameOffset)
		
		data.write(mpmFile.indexes.2 ?? 0)
		data.write(table3NameOffset)
		
		try data.writeCString(mpmFile.tableNames.0)
		
		data.seek(to: table2NameOffset)
		try data.writeCString(mpmFile.tableNames.1)
		
		if let table3Name = mpmFile.tableNames.2 {
			data.seek(to: table3NameOffset)
			try data.writeCString(table3Name)
		}
		
		self = data.data
	}
}
