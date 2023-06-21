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
	
	func save(in path: URL, carbonized: Bool, with metadata: MCMFile.Metadata?) throws {
		let filePath = path.appendingPathComponent(name)
		try contents.write(to: filePath)
		if let metadata {
			try FileManager.setCreationDate(of: filePath, to: metadata.asDate())
		}
	}
}
