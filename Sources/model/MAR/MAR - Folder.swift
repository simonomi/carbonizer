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
			if case .file(let file) = child {
				// TODO: get compression/maxchunksize
				return MCMFile(
					index: index,
					compression: (.none, .none),
					maxChunkSize: 0x2000,
					content: file
				)
			} else {
				return nil
			}
		}
	}
}

extension Folder {
	init(from marArchive: MARArchive) throws {
		name = marArchive.name + ".mar"
		// TODO: save compression/maxchunksize
		children = marArchive.contents.map { .file($0.content) }
	}
}
