//
//  MARArchive.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

struct MARArchive: FileObject {
	var name: String
	var metadata: [Metadata]
	
	var contents: [File]
}
