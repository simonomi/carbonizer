//
//  Datastream.swift
//  
//
//  Created by alice on 2023-11-18.
//

import Foundation

/// Documentation
final public class Datastream: BinaryConvertible, Codable {
	public typealias Byte = UInt8
	
	public private(set) var bytes: ArraySlice<Byte>
	public private(set) var offset: Int
	
	public convenience init(_ data: Data) {
		self.init([Byte](data))
	}
	
	public convenience init(_ bytes: [Byte]) {
		self.init(bytes[...])
	}
	
	public init(_ bytes: ArraySlice<Byte>) {
		self.bytes = bytes
		offset = bytes.startIndex
	}
	
	public convenience init(_ datastream: Datastream) {
		self.init(datastream.bytes[datastream.offset...])
	}
	
	func canRead(bytes count: Int) -> Bool {
		offset + count <= bytes.endIndex
	}
	
	func canRead(until offset: Int) -> Bool {
		offset <= bytes.endIndex
	}
	
	// MARK: codable
	public func encode(to encoder: Encoder) throws {
		try Data(bytes).encode(to: encoder)
	}
	
	public required convenience init(from decoder: Decoder) throws {
		self.init(try Data(from: decoder))
	}
}

// MARK: read
extension Datastream {
	/// Documentation
	public func read<T: BinaryConvertible>(_ type: T.Type) throws -> T {
		do {
			return try T(self)
		} catch {
			throw BinaryParserError.whileReading(T.self, error)
		}
	}
	
	/// Documentation
	public func read<T: BinaryConvertible, U: BinaryInteger>(
		_ type: [T].Type, count: U
	) throws -> [T] {
		let count = Int(count)
		do {
			return try (0..<count).map { _ in
				try read(T.self)
			}
		} catch {
			throw BinaryParserError.whileReading([T].self, count: count, error)
		}
	}
	
	/// Documentation
	public func read<T: BinaryConvertible, U: BinaryInteger>(
		_ type: [T].Type, offsets: [U], relativeTo baseOffset: Offset
	) throws -> [T] {
		let offsets = offsets.map { Int($0) + baseOffset.offest }
		do {
			return try offsets.map {
				offset = $0
				return try read(T.self)
			}
		} catch {
			throw BinaryParserError.whileReading([T].self, offsets: offsets, error)
		}
	}
}

// MARK: primitives
extension Datastream {
	/// Documentation
	public func read(_ type: UInt8.Type) throws -> UInt8 {
		guard canRead(bytes: 1) else {
			throw BinaryParserError.indexOutOfBounds(index: offset + 1, expected: bytes.indices, for: UInt8.self)
		}
		
		defer { offset += 1 }
		return bytes[offset]
	}
	
	/// Documentation
	public func read<T: BinaryInteger>(_ type: T.Type) throws -> T {
		var output = T.zero
		let byteWidth = output.bitWidth / 8
		guard canRead(bytes: byteWidth) else {
			throw BinaryParserError.indexOutOfBounds(index: offset + byteWidth, expected: bytes.indices, for: T.self)
		}
		
		let range = offset..<(offset + byteWidth)
		
		for (index, byte) in bytes[range].enumerated() {
			output |= T(byte) << (index * 8)
		}
		
		defer { offset += byteWidth }
		return output
	}
	
	/// Documentation
	public func read<T: BinaryInteger, U: BinaryInteger>(
		_ type: [T].Type, count: U
	) throws -> [T] {
		let count = Int(count)
		do {
			return try (0..<count).map { _ in
				try read(T.self)
			}
		} catch {
			throw BinaryParserError.whileReading([T].self, count: count, error)
		}
	}
	
	enum StringParsingError: Error {
		case unterminated
		case invalidUTF8
	}
	
	/// Documentation
	public func read(_ type: String.Type) throws -> String {
		guard let endIndex = bytes[offset...].firstIndex(of: 0) else {
			throw StringParsingError.unterminated
		}
		guard canRead(until: endIndex) else {
			throw BinaryParserError.indexOutOfBounds(index: endIndex, expected: bytes.indices, for: String.self)
		}
		guard let string = String(data: Data(bytes[offset..<endIndex]), encoding: .utf8) else {
			throw StringParsingError.invalidUTF8
		}
		
		defer { offset += string.utf8CString.count }
		return string
	}
	
	/// Documentation
	public func read<T: BinaryInteger>(_ type: String.Type, length: T) throws -> String {
		let endOffset = offset + Int(length)
		guard canRead(until: endOffset) else {
			throw BinaryParserError.indexOutOfBounds(index: endOffset, expected: bytes.indices, for: String.self)
		}
		guard let string = String(data: Data(bytes[offset..<endOffset]), encoding: .utf8) else {
			throw StringParsingError.invalidUTF8
		}
		
		defer { offset = endOffset }
		return string
	}
	
	/// Documentation
	public func read<T: BinaryInteger>(
		_ type: Datastream.Type, endOffset: T, relativeTo baseOffset: Offset
	) throws -> Datastream {
		let endOffset = Int(endOffset) + baseOffset.offest
		
		guard canRead(until: endOffset) else {
			throw BinaryParserError.indexOutOfBounds(index: endOffset, expected: bytes.indices, for: Datastream.self)
		}
		
		defer { offset = endOffset }
		return Datastream(bytes[offset..<endOffset])
	}
	
	/// Documentation
	public func read<T: BinaryInteger>(
		_ type: Datastream.Type, length: T
	) throws -> Datastream {
		let length = Int(length)
		
		guard canRead(bytes: length) else {
			throw BinaryParserError.indexOutOfBounds(index: offset + length, expected: bytes.indices, for: Datastream.self)
		}
		
		defer { offset += length }
		return Datastream(bytes[offset..<(offset + length)])
	}
	
	/// Documentation
	public func read<T: BinaryInteger>(
		_ type: [Datastream].Type, offsets: [T], endOffset: T, relativeTo baseOffset: Offset
	) throws -> [Datastream] {
		let offsets = offsets.map { Int($0) + baseOffset.offest }
		let endOffset = Int(endOffset) + baseOffset.offest
		
		guard canRead(until: endOffset) else {
			throw BinaryParserError.indexOutOfBounds(index: endOffset, expected: bytes.indices, for: [Datastream].self)
		}
		
		let ranges = zip(offsets, offsets.dropFirst() + [endOffset])
		defer { offset = endOffset }
		return ranges.map { start, end in
			Datastream(bytes[start..<end])
		}
	}
	
	/// Documentation
	public func read<T: BinaryInteger>(
		_ type: [Datastream].Type, startOffsets: [T], endOffsets: [T], relativeTo baseOffset: Offset
	) throws -> [Datastream] {
		assert(startOffsets.count == endOffsets.count)
		
		let startOffsets = startOffsets.map { Int($0) + baseOffset.offest }
		let endOffsets = endOffsets.map { Int($0) + baseOffset.offest }
		
		let endOffset = endOffsets.max() ?? baseOffset.offest
		guard canRead(until: endOffset) else {
			throw BinaryParserError.indexOutOfBounds(index: endOffset, expected: bytes.indices, for: [Datastream].self)
		}
		
		let ranges = zip(startOffsets, endOffsets)
		defer { offset = endOffset }
		return ranges.map { start, end in
			Datastream(bytes[start..<end])
		}
	}
}

// MARK: offset
extension Datastream {
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
extension Datastream {
	/// Documentation
	public func jump<T: BinaryInteger>(bytes: T) {
		offset += Int(bytes)
	}
	
	/// Documentation
	public func jump(to offset: Offset) {
		self.offset = offset.offest
	}
}

// MARK: joined
extension [Datastream] {
	public func joined() -> Datastream {
		Datastream(ArraySlice(map(\.bytes).joined()))
	}
}

// MARK: chunked
extension Datastream {
	public func chunked(maxSize: Int) -> [Datastream] {
		stride(from: offset, to: bytes.endIndex, by: maxSize).map {
			Datastream(bytes[$0..<min($0 + maxSize, bytes.endIndex)])
		}
	}
}
