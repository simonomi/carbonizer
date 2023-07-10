//
//  File.swift
//  
//
//  Created by simon pellerin on 2023-07-04.
//

import Foundation

extension DEXFile {
	init(named name: String, json: Data) throws {
		self.name = String(name.dropLast(9)) // remove .dex.json
		script = try JSONDecoder().decode([[Command]].self, from: json)
	}
	
	func jsonData() throws -> Data {
		try JSONEncoder(.prettyPrinted).encode(script)
	}
}
