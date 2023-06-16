//
//  BinaryFile.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

import Foundation

struct BinaryFile: FileObject {
	var name: String
	var metadata = [Metadata]()
	
	var contents: Data
}
