//
//  Datastream.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

import Foundation

class Datastream {
	let data: Data
	var offset = 0
	
	enum ReadError: Error {
		case outOfBounds(index: Int, size: Int, context: String)
		case invalidUTF8(value: [UInt8], context: String)
		case invalidCString
	}
	
	init(_ data: Data) {
		self.data = data
	}
	
	func read<T: ConvertableFromData>(
		_ type: T.Type, file: String = #file, line: Int = #line
	) throws -> T {
		let bytes = try read(T.numberOfBytes, file: file, line: line)
		if let t = T(from: bytes) {
			return t
		} else {
			let context = "file \(file) on line \(line)"
			throw ReadError.invalidUTF8(value: [UInt8](bytes), context: context)
		}
	}
	
	func read<T: BinaryInteger>(
		_ numberOfBytes: T, file: String = #file, line: Int = #line
	) throws -> Data {
		try read(to: offset + Int(numberOfBytes), file: file, line: line)
	}
	
	func read<T: BinaryInteger>(
		to endOffset: T, file: String = #file, line: Int = #line
	) throws -> Data {
		let oldOffset = offset
		offset = Int(endOffset)
		
		if offset > data.count {
			let context = "file \(file) on line \(line)"
			throw ReadError.outOfBounds(index: offset, size: data.count, context: context)
		}
		
		return data.subdata(in: oldOffset ..< offset)
	}
	
	func readString<T: BinaryInteger>(
		length: T, file: String = #file, line: Int = #line
	) throws -> String {
		let bytes = try read(length, file: file, line: line)
		if let string = String(bytes: bytes, encoding: .utf8) {
			return string
		} else {
			let context = "file \(file) on line \(line)"
			throw ReadError.invalidUTF8(value: [UInt8](bytes), context: context)
		}
	}
	
	func readCString(file: String = #file, line: Int = #line) throws -> String {
		guard let endIndex = data[offset...].firstIndex(of: 0) else {
			throw ReadError.invalidCString
		}
		let length = endIndex - offset
		return try readString(length: length, file: file, line: line)
	}
	
	func seek<T: BinaryInteger>(to offset: T) {
		self.offset = Int(offset)
	}
	
	func seek<T: BinaryInteger>(bytes numberOfBytes: T) {
		offset += Int(numberOfBytes)
	}
}
