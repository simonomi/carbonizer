//
//  DMGFile.swift
//
//
//  Created by simon pellerin on 2023-06-21.
//

import Foundation

struct DMGFile {
	var name: String
	var contents: [Line]
	
	struct Line: Codable {
		var index: UInt32
		var string: String
	}
	
	func save(in path: URL, carbonized: Bool, with metadata: MCMFile.Metadata?) throws {
		if carbonized {
			let filePath = path.appendingPathComponent(name)
			try Data(from: self).write(to: filePath)
			if let metadata {
				try FileManager.setCreationDate(of: filePath, to: metadata.asDate())
			}
		} else {
			let filePath = path.appendingPathComponent(name + ".dmg.json")
			try jsonData().write(to: filePath)
			if let metadata {
				try FileManager.setCreationDate(of: filePath, to: metadata.asDate())
			}
		}
	}
}
