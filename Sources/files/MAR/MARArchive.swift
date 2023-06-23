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
	
	func save(in path: URL, carbonized: Bool, with metadata: MCMFile.Metadata?) throws {
		if carbonized {
			let filePath = path.appendingPathComponent(name)
			try Data(from: self).write(to: filePath)
			if let metadata {
				try FileManager.setCreationDate(of: filePath, to: metadata.asDate())
			}
		} else {
			if let onlyChild {
				let file = onlyChild.content.renamed(to: name)
				let metadata = onlyChild.metadata(standalone: true)
				try file.save(in: path, carbonized: carbonized, with: metadata)
			} else {
				try Folder(from: self).save(in: path, carbonized: carbonized)
			}
		}
	}
	
	var onlyChild: MCMFile? {
		if contents.count == 1 {
			return contents.first
		} else {
			return nil
		}
	}
}
