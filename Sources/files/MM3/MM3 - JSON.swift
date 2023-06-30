//
//  MM3 - JSON.swift
//
//
//  Created by simon pellerin on 2023-06-21.
//

import Foundation

extension MM3File {
	init(named name: String, json: Data) throws {
		self.name = String(name.dropLast(9)) // remove .mm3.json
		let data = try JSONDecoder().decode(JSONData.self, from: json)
		indexes = data.indexes
		tableNames = data.tableNames
	}
	
	func jsonData() throws -> Data {
		return try JSONEncoder([.prettyPrinted, .sortedKeys]).encode(JSONData(from: self))
	}
	
	struct JSONData: Codable {
		var index1: UInt32
		var index2: UInt32
		var index3: UInt32
		
		var table1: String
		var table2: String
		var table3: String
		
		enum CodingKeys: String, CodingKey {
			case index1 = "index 1"
			case index2 = "index 2"
			case index3 = "index 3"
			case table1 = "table 1"
			case table2 = "table 2"
			case table3 = "table 3"
		}
		
		init(from mm3File: MM3File) {
			index1 = mm3File.indexes.0
			index2 = mm3File.indexes.1
			index3 = mm3File.indexes.2
			
			table1 = mm3File.tableNames.0
			table2 = mm3File.tableNames.1
			table3 = mm3File.tableNames.2
		}
		
		var indexes: (UInt32, UInt32, UInt32) {
			(index1, index2, index3)
		}
		
		var tableNames: (String, String, String) {
			(table1, table2, table3)
		}
	}
}
