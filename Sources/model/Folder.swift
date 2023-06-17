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
}
