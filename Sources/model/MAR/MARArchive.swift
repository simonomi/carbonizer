//
//  MARArchive.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

struct MARArchive {
	var name: String
	var contents: [BinaryFile]
	
	struct FileIndexTable {
		var entries: [Entry]
		
		struct Entry {
			var offset: UInt32
			var decompressedSize: UInt32
		}
	}
	
	func carbonized() throws -> FSFile {
		let carbonizedContents = MARArchive(
			name: name,
			contents: try contents.compactMap {
				if case .binaryFile(let binaryFile) = try $0.carbonized() {
					return binaryFile
				} else {
					return nil
				}
			}
		)
		return try BinaryFile(from: carbonizedContents).carbonized()
	}
	
	func uncarbonized() throws -> FSFile {
		if contents.count == 1 {
			var onlyChild = contents[0]
			onlyChild.name = name
			return try onlyChild.uncarbonized()
		}
		return try Folder(from: self).uncarbonized()
	}
}
