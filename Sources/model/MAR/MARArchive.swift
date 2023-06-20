//
//  MARArchive.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

import Foundation

struct MARArchive {
	var name: String
	var contents: [MCMFile]
	
	struct FileIndexTable {
		var entries: [Entry]
		
		struct Entry {
			var offset: UInt32
			var decompressedSize: UInt32
		}
	}
	
	func save(in path: URL, carbonized: Bool) throws {
		if carbonized {
			try Data(from: self).write(to: path.appendingPathComponent(name))
		} else {
			// TODO: re-enable once mcm files have metadata
//			if contents.count == 1 {
//				let file = contents[0].content.renamed(to: name)
//				try file.save(in: path, carbonized: carbonized)
//			} else {
				try Folder(from: self).save(in: path, carbonized: carbonized)
//			}
		}
	}
}
