//
//  BinaryFile.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

import Foundation

struct BinaryFile {
	var name: String
	var contents: Data
	
	init(named name: String, contents: Data) {
		self.name = name
		self.contents = contents
	}
	
	func save(in path: URL, carbonized: Bool) throws {
		try contents.write(to: path.appendingPathComponent(name))
	}
}
