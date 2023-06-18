//
//  Binary <-> FS.swift
//  
//
//  Created by simon pellerin on 2023-06-17.
//

import Foundation

extension BinaryFile {
	init(from path: URL) throws {
		name = path.lastPathComponent
		contents = try Data(contentsOf: path)
	}
	
	func save(in parent: URL) throws {
		try contents.write(to: parent.appending(component: name))
	}
}
