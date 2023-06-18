//
//  MARArchive.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

struct MARArchive {
	var name: String
	var contents: [File]
	
	struct FileIndexTable {
		var entries: [Entry]
		
		struct Entry {
			var offset: UInt32
			var decompressedSize: UInt32
		}
	}
}
