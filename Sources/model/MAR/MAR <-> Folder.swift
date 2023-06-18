//
//  MAR <-> Folder.swift
//  
//
//  Created by simon pellerin on 2023-06-18.
//

extension MARArchive {
	init(from folder: Folder) throws {
		name = folder.name.replacing(#/\.mar$/#, with: "")
		contents = folder.children.compactMap {
			if case .binaryFile(let binaryFile) = $0 {
				return binaryFile
			} else {
				return nil
			}
		}
	}
}

extension Folder {
	init(from marArchive: MARArchive) throws {
		name = marArchive.name + ".mar"
		children = marArchive.contents.map { .binaryFile($0) }
	}
}
