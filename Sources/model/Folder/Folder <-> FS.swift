//
//  Folder <-> FS.swift
//  
//
//  Created by simon pellerin on 2023-06-17.
//

import Foundation

extension Folder {
	init(from path: URL) throws {
		name = path.lastPathComponent
		
		
		children = try FileManager.default.contentsOfDirectory(at: path)
			.sorted(by: \.lastPathComponent)
			.filter { !$0.lastPathComponent.starts(with: ".") }
			.compactMap { child in
				switch try FileManager.type(of: child) {
					case .file:
						return .binaryFile(try BinaryFile(from: child))
					case .folder:
						return .folder(try Folder(from: child))
					case .other:
						let childPath = child.path(percentEncoded: false)
						print("warning: trying to create a folder with abnormal contents: \(childPath)")
						return nil
				}
			}
	}
	
	func save(in parent: URL) throws {
		let path = parent.appending(component: name)
		try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
		for child in children {
			switch child {
				case .folder(let folder):
					try folder.save(in: path)
				case .binaryFile(let binaryFile):
					try binaryFile.save(in: path)
				default:
					print("warning: trying to write a non-binary file to disk: \(path)/\(child.name)")
			}
		}
	}
}
