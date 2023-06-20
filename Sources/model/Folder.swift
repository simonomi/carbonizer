//
//  Folder.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

import Foundation

struct Folder {
	var name: String
	var children: [FSFile]
	
	init(named name: String, children: [FSFile]) {
		self.name = name
		self.children = children
	}
	
	init(from path: URL) throws {
		name = path.lastPathComponent
		children = try FileManager.default.contentsOfDirectory(at: path)
			.sorted(by: \.lastPathComponent)
			.filter { !$0.lastPathComponent.starts(with: ".") }
			.compactMap(FSFile.init)
	}
	
	func save(in parentPath: URL, carbonized: Bool) throws {
		let path = parentPath.appending(component: name)
		try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
		for child in children {
			switch child {
				case .folder(let folder):
					try folder.save(in: path, carbonized: carbonized)
				case .file(let file):
					try file.save(in: path, carbonized: carbonized)
			}
		}
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
	
	func getAllFiles() -> [File] {
		children.flatMap {
			switch $0 {
				case .folder(let folder):
					return folder.getAllFiles()
				case .file(let file):
					return [file]
			}
		}
	}
}
