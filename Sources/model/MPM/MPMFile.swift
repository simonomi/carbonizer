//
//  MPMFile.swift
//
//
//  Created by simon pellerin on 2023-06-21.
//

import Foundation

struct MPMFile {
	var name: String
	
	var unknown1: UInt32
	var unknown2: UInt32
	var unknown3: UInt32
	
	var width: UInt32
	var height: UInt32
	
	var unknown4: UInt32
	var unknown5: UInt32
	var unknown6: UInt32
	
	var indexes: (UInt32, UInt32, UInt32?)
	var tableNames: (String, String, String?)
	
	func save(in path: URL, carbonized: Bool, with metadata: MCMFile.Metadata?) throws {
		if carbonized {
			let filePath = path.appendingPathComponent(name)
			try Data(from: self).write(to: filePath)
			if let metadata {
				try FileManager.setCreationDate(of: filePath, to: metadata.asDate())
			}
		} else {
			let filePath = path.appendingPathComponent(name + ".mpm")
			try jsonData().write(to: filePath)
			if let metadata {
				try FileManager.setCreationDate(of: filePath, to: metadata.asDate())
			}
		}
	}
}
