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
			let endIndex = offset + inputData.count
			
			if endIndex > data.count {
				data.append(contentsOf: Array(repeating: 0, count: Int(endIndex) - data.count))
			}
			
			let range = offset ..< endIndex
			data.replaceSubrange(range, with: inputData)
		}
		offset += inputData.count
	}
	
	func seek<T: BinaryInteger>(to offset: T) {
		self.offset = Int(offset)
		if offset > data.count {
			data.append(contentsOf: Array(repeating: 0, count: Int(offset) - data.count))
		}
	}
	
	func seek<T: BinaryInteger>(bytes numberOfBytes: T) {
		seek(to: offset + Int(numberOfBytes))
	}
	
	func fourByteAlign() {
		twofiftysixByteAlign()
//		if !offset.isMultiple(of: 4) {
//			seek(bytes: 4 - (offset % 4))
//		}
	}
	
	func twofiftysixByteAlign() {
		if !offset.isMultiple(of: 0x100) {
			seek(bytes: 0x100 - (offset % 0x100))
		}
	}
}
