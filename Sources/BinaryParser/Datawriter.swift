//
//  Datawriter.swift
//
//
//  Created by alice on 2023-11-28.
//

import Foundation

final public class Datawriter {
	public typealias Byte = UInt8
	
	var bytes: ArraySlice<Byte>
	private var offset: Int
	
	public init() {
		bytes = []
		offset = bytes.endIndex
	}
	
	public func data() -> Data {
		Data(bytes)
	}
}

// MARK: write
extension Datawriter {
	/// Documentation
	public func write<T: BinaryConvertible>(_ data: T) {
		data.write(to: self)
	}
	
	/// Documentation
	public func write<T: BinaryConvertible>(_ data: [T]) {
		data.forEach(write)
	}
	
	/// Documentation
	public func write<T: BinaryConvertible, U: BinaryInteger>(
		_ data: [T], offsets: [U], relativeTo baseOffset: Offset
	) {
		let offsets = offsets.map { Int($0) + baseOffset.offest }
		
		for (offset, item) in zip(offsets, data) {
			self.offset = offset
			write(item)
		}
	}
}

// MARK: primitives
extension Datawriter {
	/// Documentation
	public func write<T: BinaryInteger>(_ data: T) {
		let byteWidth = data.bitWidth / 8
		
		let newBytes = (0..<byteWidth)
			.map { (data >> ($0 * 8)) & 0xFF }
			.map(Byte.init)
		
		bytes.insert(contentsOf: newBytes, at: self.offset)
		offset += byteWidth
	}
	
	/// Documentation
	public func write<T: BinaryInteger>(_ data: [T]) {
		data.forEach(write)
	}
	
	/// Documentation
	public func write(_ string: String) {
		let data = string.utf8CString.map(Byte.init)
		bytes.insert(contentsOf: data, at: offset)
		offset += string.utf8CString.count
	}
	
	/// Documentation
	public func write<T: BinaryInteger>(_ string: String, length: T) {
		let length = Int(length)
		
		assert(string.utf8CString.count >= length)
		let data = string.utf8CString[..<length].map(Byte.init)
		
		bytes.insert(contentsOf: data, at: offset)
		offset += length
	}
	
	/// Documentation
	public func write(_ data: Datastream) {
		bytes.insert(contentsOf: data.bytes, at: offset)
		offset += data.bytes.count
	}
	
	/// Documentation
	public func write<T: BinaryInteger>(
		_ data: Datastream, length: T
	) {
		let length = Int(length)
		
		assert(data.bytes.count >= length)
		bytes.insert(contentsOf: data.bytes[..<length], at: offset)
		offset += length
	}
	
	/// Documentation
	public func write<T: BinaryInteger>(
		_ data: [Datastream], offsets: [T], relativeTo baseOffset: Offset
	) {
		let offsets = offsets.map { Int($0) + baseOffset.offest }
		
		for (offset, item) in zip(offsets, data) {
			self.offset = offset
			write(item)
		}
	}
	
	/// Documentation
//	public func write<T: BinaryInteger>(
//		_ data: [Datastream], startOffsets: [T], endOffsets: [T], relativeTo baseOffset: Offset
//	) {
//	}
}

// MARK: offset
extension Datawriter {
	public struct Offset {
		var offest: Int
		
		init(_ offest: Int) {
			self.offest = offest
		}
		
		public static func + <T: BinaryInteger>(lhs: Offset, rhs: T) -> Offset {
			Offset(lhs.offest + Int(rhs))
		}
	}
	
	/// Documentation
	public func placeMarker() -> Offset {
		Offset(offset)
	}
}

// MARK: jump
extension Datawriter {
	/// Documentation
	public func jump<T: BinaryInteger>(bytes: T) {
		offset += Int(bytes)
	}
	
	/// Documentation
	public func jump(to offset: Offset) {
		self.offset = offset.offest
	}
}

