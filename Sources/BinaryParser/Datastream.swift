import Foundation

/// Documentation
final public class Datastream: BinaryConvertible, Codable {
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
		canRead(until: offset + count)
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
	@inlinable
	public func read<T: BinaryConvertible>(_ type: T.Type) throws -> T {
		do {
			return try T(self)
		} catch {
			throw BinaryParserError.whileReading(T.self, error)
		}
	}
	
	@inlinable
	public func read<T: BinaryConvertible>(
		_ type: [T].Type, count: some BinaryInteger
	) throws -> [T] {
		let count = Int(count)
		do {
			return try (0..<count).map { _ in
				try read(T.self)
			}
		} catch {
			throw BinaryParserError.whileReading([T].self, error)
		}
	}
	
	@inlinable
	public func read<T: BinaryConvertible>(
		_ type: [T].Type, offsets: [some BinaryInteger], relativeTo baseOffset: Offset
	) throws -> [T] {
		let offsets = offsets.map { Int($0) + baseOffset.offset }
		do {
			return try offsets.map {
				offset = $0
				return try read(T.self)
			}
		} catch {
			throw BinaryParserError.whileReading([T].self, error)
		}
	}
}

// MARK: primitives
extension Datastream {
	@inlinable
	public func read(_ type: UInt8.Type) throws -> UInt8 {
		guard canRead(bytes: 1) else {
			throw BinaryParserError.indexOutOfBounds(
				index: offset + 1,
				expected: bytes.indices,
				whileReading: UInt8.self
			)
		}
		
		defer { offset += 1 }
		return bytes[offset]
	}
	
	// special case for Int8 so that UInt8 -> Int8 doesnt overflow
	@inlinable
	public func read(_ type: Int8.Type) throws -> Int8 {
		guard canRead(bytes: 1) else {
			throw BinaryParserError.indexOutOfBounds(
				index: offset + 1,
				expected: bytes.indices,
				whileReading: Int8.self
			)
		}
		
		defer { offset += 1 }
		return Int8(bitPattern: bytes[offset])
	}
	
	@inlinable
	public func read<T: FixedWidthInteger>(_ type: T.Type) throws -> T {
		let byteWidth = T.bitWidth / 8
		guard canRead(bytes: byteWidth) else {
			throw BinaryParserError.indexOutOfBounds(
				index: offset + byteWidth,
				expected: bytes.indices,
				whileReading: T.self
			)
		}
		
		let range = offset..<(offset + byteWidth)
		
		defer { offset += byteWidth }
		
		return bytes[range]
			.enumerated()
			.map { (index, byte) in
				T(byte) << (index * 8)
			}
			.reduce(T.zero, |)
		
		// this unsafe version is ~.05s faster over the whole nds
//		return bytes[range].withUnsafeBufferPointer {
//			$0.withMemoryRebound(to: T.self) {
//				$0[0]
//			}
//		}
	}
	
	@inlinable
	public func read<T: FixedWidthInteger>(
		_ type: [T].Type, count: some BinaryInteger
	) throws -> [T] {
		let count = Int(count)
		do {
			return try (0..<count).map { _ in
				try read(T.self)
			}
		} catch {
			throw BinaryParserError.whileReading([T].self, error)
		}
	}
	
	@usableFromInline
	enum StringParsingError: Error {
		case unterminated
		case invalidUTF8(String)
	}
	
	@inlinable
	public func read(_ type: String.Type) throws -> String {
		guard canRead(until: offset) else {
			throw BinaryParserError.indexOutOfBounds(
				index: offset,
				expected: bytes.indices,
				whileReading: String.self
			)
		}
		guard let endIndex = bytes[offset...].firstIndex(of: 0) else {
			throw StringParsingError.unterminated
		}
		guard canRead(until: endIndex) else {
			throw BinaryParserError.indexOutOfBounds(
				index: endIndex,
				expected: bytes.indices,
				whileReading: String.self
			)
		}
		guard let string = String(bytes: bytes[offset..<endIndex], encoding: .utf8) else {
			throw StringParsingError.invalidUTF8(showInvalidUTF8(in: bytes[offset..<endIndex]))
		}
		
		defer { offset += string.utf8CString.count }
		return string
	}
	
	@inlinable
	public func read(
		_ type: [String].Type, count: some BinaryInteger
	) throws -> [String] {
		let count = Int(count)
		do {
			return try (0..<count).map { _ in
				try read(String.self)
			}
		} catch {
			throw BinaryParserError.whileReading([String].self, error)
		}
	}
	
	@inlinable
	public func read(
		_ type: [String].Type, offsets: [some BinaryInteger], relativeTo baseOffset: Offset
	) throws -> [String] {
		do {
			return try offsets.map {
				jump(to: baseOffset + $0)
				return try read(String.self)
			}
		} catch {
			throw BinaryParserError.whileReading([String].self, error)
		}
	}
	
	@inlinable
	public func read(
		_ type: [[String]].Type, offsets: [[some BinaryInteger]], relativeTo baseOffset: Offset
	) throws -> [[String]] {
		do {
			return try offsets.map {
				try $0.map {
					jump(to: baseOffset + $0)
					return try read(String.self)
				}
			}
		} catch {
			throw BinaryParserError.whileReading([[String]].self, error)
		}
	}
	
	@inlinable
	public func read(_ type: String.Type, length inputLength: some BinaryInteger) throws -> String {
		guard canRead(until: offset) else {
			throw BinaryParserError.indexOutOfBounds(
				index: offset,
				expected: bytes.indices,
				whileReading: String.self
			)
		}
		
		let inputEndOffset = offset + Int(inputLength)
		
		let nullByteOffset = bytes[offset...].firstIndex(of: 0) ?? .max
		let endOffset = min(inputEndOffset, nullByteOffset)
		
		guard canRead(until: endOffset) else {
			throw BinaryParserError.indexOutOfBounds(
				index: endOffset,
				expected: bytes.indices,
				whileReading: String.self
			)
		}
		guard let string = String(bytes: bytes[offset..<endOffset], encoding: .utf8) else {
			throw StringParsingError.invalidUTF8(showInvalidUTF8(in: bytes[offset..<endOffset]))
		}
		
		defer { offset = inputEndOffset }
		return string
	}
	
	@inlinable
	public func read(_ type: String.Type, exactLength inputLength: some BinaryInteger) throws -> String {
		let endOffset = offset + Int(inputLength)
		
		guard canRead(until: endOffset) else {
			throw BinaryParserError.indexOutOfBounds(
				index: endOffset,
				expected: bytes.indices,
				whileReading: String.self
			)
		}
		guard let string = String(bytes: bytes[offset..<endOffset], encoding: .utf8) else {
			throw StringParsingError.invalidUTF8(showInvalidUTF8(in: bytes[offset..<endOffset]))
		}
		
		defer { offset = endOffset }
		return string
	}
	
	@inlinable
	public func read(
		_ type: Datastream.Type, endOffset: some BinaryInteger, relativeTo baseOffset: Offset
	) throws -> Datastream {
		let endOffset = Int(endOffset) + baseOffset.offset
		
		guard canRead(until: endOffset) else {
			throw BinaryParserError.indexOutOfBounds(
				index: endOffset,
				expected: bytes.indices,
				whileReading: Datastream.self
			)
		}
		
		defer { offset = endOffset }
		return Datastream(bytes[offset..<endOffset])
	}
	
	@inlinable
	public func read(
		_ type: Datastream.Type, length: some BinaryInteger
	) throws -> Datastream {
		let length = Int(length)
		
		guard canRead(bytes: length) else {
			throw BinaryParserError.indexOutOfBounds(
				index: offset + length,
				expected: bytes.indices,
				whileReading: Datastream.self
			)
		}
		
		defer { offset += length }
		return Datastream(bytes[offset..<(offset + length)])
	}
	
	@inlinable
	public func read<T: BinaryInteger>(
		_ type: [Datastream].Type, offsets: [T], endOffset: T, relativeTo baseOffset: Offset
	) throws -> [Datastream] {
		let offsets = offsets.map { Int($0) + baseOffset.offset }
		let endOffset = Int(endOffset) + baseOffset.offset
		
		guard canRead(until: endOffset) else {
			throw BinaryParserError.indexOutOfBounds(
				index: endOffset,
				expected: bytes.indices,
				whileReading: [Datastream].self
			)
		}
		
		let ranges = zip(offsets, offsets.dropFirst() + [endOffset])
		defer { offset = endOffset }
		return try ranges.map { start, end in
			guard start <= end else {
				throw BinaryParserError.indexOutOfBounds(index: end, expected: start..<endOffset)
			}
			
			return Datastream(bytes[start..<end])
		}
	}
	
	@inlinable
	public func read<T: BinaryInteger>(
		_ type: [Datastream].Type, startOffsets: [T], endOffsets: [T], relativeTo baseOffset: Offset
	) throws -> [Datastream] {
		assert(startOffsets.count == endOffsets.count)
		
		let startOffsets = startOffsets.map { Int($0) + baseOffset.offset }
		let endOffsets = endOffsets.map { Int($0) + baseOffset.offset }
		
		let endOffset = endOffsets.max() ?? baseOffset.offset
		guard canRead(until: endOffset) else {
			throw BinaryParserError.indexOutOfBounds(
				index: endOffset,
				expected: bytes.indices,
				whileReading: [Datastream].self
			)
		}
		
		let ranges = zip(startOffsets, endOffsets)
		defer { offset = endOffset }
		return ranges.map { start, end in
			Datastream(bytes[start..<end])
		}
	}
	
	@inlinable
	public func read(_: ()) throws {}
}

// MARK: offset
extension Datastream {
	public struct Offset {
		@usableFromInline
		var offset: Int
		
		@inlinable
		init(_ offest: Int) {
			self.offset = offest
		}
		
		@inlinable
		public static func + <T: BinaryInteger>(lhs: Offset, rhs: T) -> Offset {
			Offset(lhs.offset + Int(rhs))
		}
	}
	
	@inlinable
	public func placeMarker() -> Offset {
		Offset(offset)
	}
}

// MARK: jump
extension Datastream {
	@inlinable
	public func jump(bytes: some BinaryInteger) {
		offset += Int(bytes)
	}
	
	@inlinable
	public func jump(to offset: Offset) {
		self.offset = offset.offset
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
