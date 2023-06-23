//
//  File.swift
//  
//
//  Created by simon pellerin on 2023-06-21.
//

import Foundation

extension DMSFile {
	init(named name: String, from inputData: Data) throws {
		self.name = name
		
		let data = Datastream(inputData)
		data.seek(to: 4)
		maxId = try data.read(UInt32.self)
	}
}

extension Data {
	init(from dmsFile: DMSFile) throws {
		let data = Datawriter()
		
		try data.write("DMS\0")
		data.write(dmsFile.maxId)
		
		self = data.data
	}
}
