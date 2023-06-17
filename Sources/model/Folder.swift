//
//  Folder.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

struct Folder {
	var name: String
	var children: [File]
	
	func getChild(named name: String) -> File? {
		children.first { $0.name == name }
	}
	
	func getFolderTree() -> [Folder] {
		[self] + children.flatMap {
			if case .folder(let folder) = $0 {
				return folder.getFolderTree()
			} else {
				return []
			}
		}
	}
	
	func getAllBinaryFiles() -> [BinaryFile] {
		children.flatMap {
			switch $0 {
				case .folder(let folder):
					return folder.getAllBinaryFiles()
				case .binaryFile(let binaryFile):
					return [binaryFile]
				default:
					return []
			}
		}
	}
}
