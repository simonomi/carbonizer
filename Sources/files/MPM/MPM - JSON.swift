//
//  MPM - JSON.swift
//
//
//  Created by simon pellerin on 2023-06-21.
//

import Foundation

extension MPMFile {
	init(named name: String, json: Data) throws {
		self.name = String(name.dropLast(9)) // remove .mpm.json
		let data = try JSONDecoder().decode(JSONData.self, from: json)
		unknown1 = data.unknown1
		unknown2 = data.unknown2
		unknown3 = data.unknown3
		
		width = data.width
		height = data.height
		
		unknown4 = data.unknown4
		unknown5 = data.unknown5
		unknown6 = data.unknown6
		
		indexes = data.indexes
		tableNames = data.tableNames
	}
	
	func jsonData() throws -> Data {
		return try JSONEncoder(.prettyPrinted, .sortedKeys).encode(JSONData(from: self))
	}
	
	struct JSONData: Codable {
		var unknown1: UInt32
		var unknown2: UInt32
		var unknown3: UInt32
		
		var width: UInt32
		var height: UInt32
		
		var unknown4: UInt32
		var unknown5: UInt32
		var unknown6: UInt32
		
		var colorPaletteIndex: UInt32
		var colorPaleteTableName: String
		
		var bitmapIndex: UInt32
		var bitmapTableName: String
		
		var bgMapIndex: UInt32
		var bgMapTableName: String
		
		enum CodingKeys: String, CodingKey {
			case unknown1 = "unknown 1"
			case unknown2 = "unknown 2"
			case unknown3 = "unknown 3"
			case width, height
			case unknown4 = "unknown 4"
			case unknown5 = "unknown 5"
			case unknown6 = "unknown 6"
			case colorPaletteIndex = "color palette index"
			case colorPaleteTableName = "color palete table name"
			case bitmapIndex = "bitmap index"
			case bitmapTableName = "bitmap table name"
			case bgMapIndex = "bg map index"
			case bgMapTableName = "bg map table name"
		}
		
		init(from mpmFile: MPMFile) {
			unknown1 = mpmFile.unknown1
			unknown2 = mpmFile.unknown2
			unknown3 = mpmFile.unknown3
			
			width = mpmFile.width
			height = mpmFile.height
			
			unknown4 = mpmFile.unknown4
			unknown5 = mpmFile.unknown5
			unknown6 = mpmFile.unknown6
			
			colorPaletteIndex = mpmFile.indexes.0
			colorPaleteTableName = mpmFile.tableNames.0
			
			bitmapIndex = mpmFile.indexes.1
			bitmapTableName = mpmFile.tableNames.1
			
			bgMapIndex = mpmFile.indexes.2 ?? 0
			bgMapTableName = mpmFile.tableNames.2 ?? ""
		}
		
		var indexes: (UInt32, UInt32, UInt32?) {
			let index3 = bgMapIndex == 0 ? nil : bgMapIndex
			return (colorPaletteIndex, bitmapIndex, index3)
		}
		
		var tableNames: (String, String, String?) {
			let tableName3 = bgMapTableName == "" ? nil : bgMapTableName
			return (colorPaleteTableName, bitmapTableName, tableName3)
		}
	}
}
