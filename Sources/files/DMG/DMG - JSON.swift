//
//  File.swift
//  
//
//  Created by simon pellerin on 2023-06-21.
//

import Foundation

extension DMGFile {
	init(named name: String, json: Data) throws {
		self.name = String(name.dropLast(4)) // remove .dmg
		contents = try JSONDecoder().decode([Line].self, from: json)
	}
	
	func jsonData() throws -> Data {
		try JSONEncoder(.prettyPrinted).encode(contents)
	}
}
