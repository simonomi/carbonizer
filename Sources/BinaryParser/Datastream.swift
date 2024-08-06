import Foundation

/// Documentation
final public class Datastream: BinaryConvertible, Codable {
	public typealias Byte = UInt8
	
	public let bytes: ArraySlice<Byte> // for inlinability
	
//	public private(set) var offset: Int
	public var offset: Int // for inlinability
	
	@inlinable
	public convenience init() {
		self.init([])
	}
	
	@inlinable
	public convenience init(_ data: Data) {
		self.init([Byte](data))
	}
	
	@inlinable
	public convenience init(_ bytes: [Byte]) {
		self.init(bytes[...])
	}
	
	@inlinable
	public init(_ bytes: ArraySlice<Byte>) {
		self.bytes = bytes
		offset = bytes.startIndex
	}
	
	@inlinable
	public convenience init(_ datastream: Datastream) {
		self.init(datastream.bytes[datastream.offset...])
	}
	
	@inlinable
	func canRead(bytes count: Int) -> Bool {
		offset + count <= bytes.endIndex
	}
	
	@inlinable
	func canRead(until offset: Int) -> Bool {
		offset <= bytes.endIndex
	}
	
	// MARK: codable
	@inlinable
	public func encode(to encoder: Encoder) throws {
		try Data(bytes).encode(to: encoder)
	}
	
	@inlinable
	public required convenience init(from decoder: Decoder) throws {
		self.init(try Data(from: decoder))
	}
}

// MARK: read
extension Datastream {
	/// Documentation
	@inlinable
	public func read<T: BinaryConvertible>(_ type: T.Type) throws -> T {
		do {
			return try T(self)
		} catch {
			throw BinaryParserError.whileReading(T.self, error)
		}
	}
	
	/// Documentation
	@inlinable
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
	@inlinable
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
	@inlinable
	public func read(_ type: UInt8.Type) throws -> UInt8 {
		guard canRead(bytes: 1) else {
			throw BinaryParserError.indexOutOfBounds(index: offset + 1, expected: bytes.indices, for: UInt8.self)
		}
		
		defer { offset += 1 }
		return bytes[offset]
	}
	
	// special case for Int8 so that UInt8 -> Int8 doesnt overflow
	@inlinable
	public func read(_ type: Int8.Type) throws -> Int8 {
		guard canRead(bytes: 1) else {
			throw BinaryParserError.indexOutOfBounds(index: offset + 1, expected: bytes.indices, for: Int8.self)
		}
		
		defer { offset += 1 }
		return Int8(bitPattern: bytes[offset])
	}
	
	/// Documentation
	@inlinable
	public func read<T: FixedWidthInteger>(_ type: T.Type) throws -> T {
		let byteWidth = T.bitWidth / 8
		guard canRead(bytes: byteWidth) else {
			throw BinaryParserError.indexOutOfBounds(index: offset + byteWidth, expected: bytes.indices, for: T.self)
		}
		
		let range = offset..<(offset + byteWidth)
		
		let output = bytes[range]
			.enumerated()
			.map { (index, byte) in
				T(byte) << (index * 8)
			}
			.reduce(T.zero, |)
		
		defer { offset += byteWidth }
		return output
	}
	
	/// Documentation
	@inlinable
	public func read<T: FixedWidthInteger, U: BinaryInteger>(
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
	
	@usableFromInline
	enum StringParsingError: Error {
		case unterminated
		case invalidUTF8(String)
	}
	
	/// Documentation
	@inlinable
	public func read(_ type: String.Type) throws -> String {
		guard let endIndex = bytes[offset...].firstIndex(of: 0) else {
			throw StringParsingError.unterminated
		}
		guard canRead(until: endIndex) else {
			throw BinaryParserError.indexOutOfBounds(index: endIndex, expected: bytes.indices, for: String.self)
		}
		guard let string = String(data: Data(bytes[offset..<endIndex]), encoding: .utf8) else {
			throw StringParsingError.invalidUTF8(showInvalidUTF8(in: bytes[offset..<endIndex]))
		}
		
		defer { offset += string.utf8CString.count }
		return string
	}
	
	/// Documentation
	@inlinable
	public func read<T: BinaryInteger>(_ type: String.Type, length inputLength: T) throws -> String {
		let inputEndOffset = offset + Int(inputLength)
		
		let nullByteOffset = bytes[offset...].firstIndex(of: 0) ?? .max
		let endOffset = min(inputEndOffset, nullByteOffset)
		
		guard canRead(until: endOffset) else {
			throw BinaryParserError.indexOutOfBounds(index: endOffset, expected: bytes.indices, for: String.self)
		}
		guard let string = String(data: Data(bytes[offset..<endOffset]), encoding: .utf8) else {
			throw StringParsingError.invalidUTF8(showInvalidUTF8(in: bytes[offset..<endOffset]))
		}
		
		defer { offset = inputEndOffset }
		return string
	}
	
	/// Documentation
	@inlinable
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
	@inlinable
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
	@inlinable
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
	@inlinable
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
		@usableFromInline
		var offest: Int
		
		@inlinable
		init(_ offest: Int) {
			self.offest = offest
		}
		
		@inlinable
		public static func + <T: BinaryInteger>(lhs: Offset, rhs: T) -> Offset {
			Offset(lhs.offest + Int(rhs))
		}
	}
	
	/// Documentation
	@inlinable
	public func placeMarker() -> Offset {
		Offset(offset)
	}
}

// MARK: jump
extension Datastream {
	/// Documentation
	@inlinable
	public func jump<T: BinaryInteger>(bytes: T) {
		offset += Int(bytes)
	}
	
	/// Documentation
	@inlinable
	public func jump(to offset: Offset) {
		self.offset = offset.offest
	}
}

// MARK: joined
extension [Datastream] {
	@inlinable
	public func joined() -> Datastream {
		Datastream(ArraySlice(map(\.bytes).joined()))
	}
}

// MARK: chunked
extension Datastream {
	@inlinable
	public func chunked(maxSize: Int) -> [Datastream] {
		stride(from: offset, to: bytes.endIndex, by: maxSize).map {
			Datastream(bytes[$0..<min($0 + maxSize, bytes.endIndex)])
		}
	}
}
