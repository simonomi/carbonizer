//
//  DTX - JSON.swift
//
//
//  Created by simon pellerin on 2023-06-21.
//

import Foundation

extension DTXFile {
	init(named name: String, json: Data) throws {
		self.name = String(name.dropLast(9)) // remove .dtx.json
		contents = try JSONDecoder().decode([String].self, from: json)
	}
	
	func jsonData() throws -> Data {
		try JSONEncoder(.prettyPrinted).encode(contents)
	}
}
