//
//  DMG - Binary.swift
//
//
//  Created by simon pellerin on 2023-06-21.
//

import Foundation

extension DMGFile {
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
			return try Line(from: data)
		}
	}
}

extension DMGFile.Line {
	init(from data: Datastream) throws {
		index = try data.read(UInt32.self)
		data.seek(bytes: 4)
		string = try data.readCString()
	}
	
	func write(to data: Datawriter) throws {
		data.write(index)
		data.write(UInt32(8))
		try data.writeCString(string)
	}
}

extension Data {
	init(from dmgFile: DMGFile) throws {
		let data = Datawriter()
		
		try data.write("DMG\0")
		
		data.write(UInt32(dmgFile.contents.count))
		
		let indexesOffset = data.offset + 4
		data.write(UInt32(indexesOffset))
		
		var stringIndexes = [UInt32(data.offset + (4 * dmgFile.contents.count))]
		data.seek(to: stringIndexes.first!)
		
		try dmgFile.contents.forEach {
			try $0.write(to: data)
			data.fourByteAlign()
			
			stringIndexes.append(UInt32(data.offset))
		}
		
		data.seek(to: indexesOffset)
		for index in stringIndexes.dropLast() {
			data.write(index)
		}
		
		self = data.data
	}
}
