//
//  File.swift
//  
//
//  Created by simon pellerin on 2023-07-01.
//

import Foundation

extension RLSFile {
	init(named name: String, json: Data) throws {
		self.name = String(name.dropLast(9)) // remove .rls.json
		kasekis = try JSONDecoder().decode([Kaseki?].self, from: json)
	}
	
	func jsonData() throws -> Data {
		try JSONEncoder(.prettyPrinted, .sortedKeys).encode(kasekis)
	}
}
