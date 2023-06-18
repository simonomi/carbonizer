//
//  Folder.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

struct Folder {
	var name: String
	var children: [File]
	
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
	
	func carbonized() throws -> FSFile {
		let carbonizedChildren = Folder(
			name: name,
			children: try children.map { try $0.carbonized().asFile }
		)
		
		if getChild(named: "header.json") != nil {
			return try NDSFile(from: carbonizedChildren).carbonized()
		} else if name.hasSuffix(".mar") {
			return try MARArchive(from: carbonizedChildren).carbonized()
		}
		
		return .folder(carbonizedChildren)
	}
	
	func uncarbonized() throws -> FSFile {
		let uncarbonizedChildren = Folder(
			name: name,
			children: try children.map { try $0.uncarbonized().asFile }
		)
		return .folder(uncarbonizedChildren)
	}
}
