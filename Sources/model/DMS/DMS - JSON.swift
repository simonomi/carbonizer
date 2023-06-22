//
//  File.swift
//  
//
//  Created by simon pellerin on 2023-06-21.
//

import Foundation

extension DMSFile {
	init(named name: String, json: Data) throws {
		self.name = String(name.dropLast(4)) // remove .dms
		maxId = try JSONDecoder().decode(UInt32.self, from: json)
	}
	
	func jsonData() throws -> Data {
		try JSONEncoder(.prettyPrinted).encode(maxId)
	}
}
