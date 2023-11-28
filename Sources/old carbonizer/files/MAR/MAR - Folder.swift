//
//  MAR <-> Folder.swift
//  
//
//  Created by simon pellerin on 2023-06-18.
//

extension MARArchive {
	init(from folder: Folder) throws {
		name = String(folder.name.dropLast(4)) // remove .mar
		contents = folder.children.enumerated().compactMap { index, child in
			if case .file(let file, let metadata) = child, let metadata {
				return MCMFile(from: file, with: metadata)
			} else {
				return nil
			}
		}
	}
}

extension Folder {
	init(from marArchive: MARArchive) throws {
		name = marArchive.name + ".mar"
		children = marArchive.contents.map { .file($0.content, $0.metadata(standalone: false)) }
	}
}
