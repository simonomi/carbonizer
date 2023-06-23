//
//  DTX - Binary.swift
//
//
//  Created by simon pellerin on 2023-06-21.
//

import Foundation

extension DTXFile {
	init(named name: String, from inputData: Data) throws {
		self.name = name
		
		let data = Datastream(inputData)
		
		data.seek(to: 4)
		
		let numberOfStrings = try data.read(UInt32.self)
		let indexesOffset = try data.read(UInt32.self)
		
		data.seek(to: indexesOffset)
		
		let indexes = try (0 ..< numberOfStrings).map { _ in
			try data.read(UInt32.self)
		}
		
		contents = try indexes.map {
			data.seek(to: $0)
			return try data.readCString()
		}
	}
}

extension Data {
	init(from dtxFile: DTXFile) throws {
		let data = Datawriter()
		
		try data.write("DTX\0")
		
		data.write(UInt32(dtxFile.contents.count))
		
		let indexesOffset = data.offset + 4
		data.write(UInt32(indexesOffset))
		
		var stringIndex = UInt32(data.offset + (4 * dtxFile.contents.count))
		dtxFile.contents.forEach {
			data.write(stringIndex)
			stringIndex += UInt32($0.utf8CString.count)
		}
		
		try dtxFile.contents.forEach {
			try data.writeCString($0)
		}
		
		self = data.data
	}
}
