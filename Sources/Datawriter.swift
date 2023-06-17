//
//  Datawriter.swift
//  
//
//  Created by simon pellerin on 2023-06-17.
//

import Foundation

class Datawriter {
	var data = Data()
	var offset = 0
	
	enum WriteError: Error {
		case invalidUTF8(value: String, context: String)
	}
	
	init() {}
	
	func write(_ string: String, file: String = #file, line: Int = #line) throws {
		if let data = string.data(using: .utf8) {
			write(data)
		} else {
			let context = "file \(file) on line \(line)"
			throw WriteError.invalidUTF8(value: string, context: context)
		}
	}
	
	func write<T: ConvertableFromData>(_ int: T) {
		write(int.asData)
	}
	
	func write(_ inputData: Data) {
		if offset == data.count {
			data.append(inputData)
		} else {
			let range = offset ..< offset + inputData.count
			data.replaceSubrange(range, with: inputData)
		}
	}
	
	func seek<T: BinaryInteger>(to offset: T) {
		self.offset = Int(offset)
		if data.count < offset {
			data.append(contentsOf: Array(repeating: 0, count: Int(offset) - data.count))
		}
	}
	
	func seek<T: BinaryInteger>(bytes numberOfBytes: T) {
		seek(to: offset + Int(numberOfBytes))
	}
	
	func fourByteAlign() {
		seek(bytes: 4 - (offset % 4))
	}
}
