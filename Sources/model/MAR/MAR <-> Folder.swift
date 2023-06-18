//
//  MAR <-> Folder.swift
//  
//
//  Created by simon pellerin on 2023-06-18.
//

extension MARArchive {
	init(from folder: Folder) throws {
		name = folder.name
		contents = folder.children
	}
}

extension Folder {
	init(from marArchive: MARArchive) throws {
		name = marArchive.name + ".mar" // TODO: ?
		children = marArchive.contents
	}
}
