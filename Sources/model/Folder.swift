//
//  Folder.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

struct Folder: FileObject {
	var name: String
	var metadata = [Metadata]()
	
	var children: [File]
}
