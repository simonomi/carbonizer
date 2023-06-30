//
//  DTXFile.swift
//
//
//  Created by simon pellerin on 2023-06-21.
//

import Foundation

struct DTXFile {
	var name: String
	var contents: [String]
	
	func save(in path: URL, carbonized: Bool, with metadata: MCMFile.Metadata?) throws {
		if carbonized {
			let filePath = path.appendingPathComponent(name)
			try Data(from: self).write(to: filePath)
			if let metadata {
				try FileManager.setCreationDate(of: filePath, to: metadata.asDate())
			}
		} else {
			let filePath = path.appendingPathComponent(name + ".dtx.json")
			try jsonData().write(to: filePath)
			if let metadata {
				try FileManager.setCreationDate(of: filePath, to: metadata.asDate())
			}
		}
	}
}
