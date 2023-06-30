//
//  File.swift
//  
//
//  Created by simon pellerin on 2023-06-21.
//

import Foundation

struct MM3File {
	var name: String
	var indexes: (UInt32, UInt32, UInt32)
	var tableNames: (String, String, String)
	
	func save(in path: URL, carbonized: Bool, with metadata: MCMFile.Metadata?) throws {
		if carbonized {
			let filePath = path.appendingPathComponent(name)
			try Data(from: self).write(to: filePath)
			if let metadata {
				try FileManager.setCreationDate(of: filePath, to: metadata.asDate())
			}
		} else {
			let filePath = path.appendingPathComponent(name + ".mm3.json")
			try jsonData().write(to: filePath)
			if let metadata {
				try FileManager.setCreationDate(of: filePath, to: metadata.asDate())
			}
		}
	}
}
