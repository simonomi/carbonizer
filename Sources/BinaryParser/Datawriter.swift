import Foundation

final public class Datawriter {
	public typealias Byte = UInt8
	
//	public private(set) var bytes: ArraySlice<Byte>
	public var bytes: ArraySlice<Byte> // for inlinability
	
//	public private(set) var offset: Int
	public var offset: Int // for inlinability
	
	@inlinable
	public init() {
		bytes = []
		offset = bytes.endIndex
	}
	
	@inlinable
	public init(capacity: Int) {
		bytes = []
		bytes.reserveCapacity(capacity)
		offset = bytes.endIndex
	}
	
	@inlinable
	public func intoDatastream() -> Datastream {
		Datastream(bytes)
	}
}

// MARK: write
extension Datawriter {
	/// Documentation
	@inlinable
	public func write(_ data: some BinaryConvertible) {
		data.write(to: self)
	}
	
	/// Documentation
	@inlinable
	public func write(_ data: some Sequence<some BinaryConvertible>) {
		data.forEach(write)
	}
	
	/// Documentation
	@inlinable
	public func write(
		_ data: [some BinaryConvertible],
		offsets: [some BinaryInteger],
		relativeTo baseOffset: Offset
	) {
		let offsets = offsets.map { Int($0) + baseOffset.offest }
		
		for (offset, item) in zip(offsets, data) {
			jump(to: Offset(offset))
			write(item)
		}
	}
}

// MARK: primitives
extension Datawriter {
	/// Documentation
	@inlinable
	public func write(_ byte: Byte) {
		if offset == bytes.endIndex {
			bytes.insert(byte, at: offset)
		} else {
			assert(bytes[offset] == fillerByte)
			bytes[offset] = byte
		}
		
		offset += 1
	}
	
	/// Documentation
	@inlinable
	public func write<T: FixedWidthInteger>(_ data: T) {
		let byteWidth = T.bitWidth / 8
		
		let newBytes = (0..<byteWidth)
			.map { (data >> ($0 * 8)) & 0xFF }
			.map(Byte.init)
		
		if offset == bytes.endIndex {
			bytes.insert(contentsOf: newBytes, at: offset)
		} else {
			let endIndex = offset + byteWidth
			assert(bytes[offset..<endIndex].allSatisfy { $0 == fillerByte })
			bytes.replaceSubrange(offset..<endIndex, with: newBytes)
		}
		offset += byteWidth
	}
	
	/// Documentation
	@inlinable
	public func write(_ data: some Sequence<some FixedWidthInteger>) {
		data.forEach(write)
	}
	
	/// Documentation
	@inlinable
	public func write(_ string: String) {
		let data = string.utf8CString.map(Byte.init)
		if offset == bytes.endIndex {
			bytes.insert(contentsOf: data, at: offset)
		} else {
			let endIndex = offset + data.count
			assert(bytes[offset..<endIndex].allSatisfy { $0 == fillerByte })
			bytes.replaceSubrange(offset..<endIndex, with: data)
		}
		offset += string.utf8CString.count
	}
	
	/// Documentation
	@inlinable
	public func write(
		_ data: [String], offsets: [some BinaryInteger], relativeTo baseOffset: Offset
	) {
		let offsets = offsets.map { Int($0) + baseOffset.offest }
		
		for (offset, item) in zip(offsets, data) {
			jump(to: Offset(offset))
			write(item)
		}
	}
	
	/// Documentation
	@inlinable
	public func write(_ string: String, length: some BinaryInteger) {
		let length = Int(length)
		
		var string = string
		if string.utf8CString.count < length {
			string = string.padded(toLength: length, with: "\0", from: .trailing)
		}
		let data = string.utf8CString[..<length].map(Byte.init)
		
		if offset == bytes.endIndex {
			bytes.insert(contentsOf: data, at: offset)
		} else {
			let endIndex = offset + data.count
			assert(bytes[offset..<endIndex].allSatisfy { $0 == fillerByte })
			bytes.replaceSubrange(offset..<endIndex, with: data)
		}
		offset += length
	}
	
	/// Documentation
	@inlinable
	public func write(_ data: Datastream) {
		if offset == bytes.endIndex {
			bytes.insert(contentsOf: data.bytes[data.offset...], at: offset)
		} else {
			let endIndex = offset + data.bytes[data.offset...].count
			assert(bytes[offset..<endIndex].allSatisfy { $0 == fillerByte })
			bytes.replaceSubrange(offset..<endIndex, with: data.bytes[data.offset...])
		}
		offset += data.bytes.count
	}
	
	/// Documentation
	@inlinable
	public func write(
		_ data: Datastream, length: some BinaryInteger
	) {
		let length = Int(length)
		
		let endIndex = data.offset + length
		assert(data.canRead(until: endIndex))
		if offset == bytes.endIndex {
			bytes.insert(contentsOf: data.bytes[data.offset..<endIndex], at: offset)
		} else {
			let endIndex = offset + data.bytes[data.offset..<endIndex].count
			assert(bytes[offset..<endIndex].allSatisfy { $0 == fillerByte })
			bytes.replaceSubrange(offset..<endIndex, with: data.bytes[data.offset..<endIndex])
		}
		offset += length
	}
	
	/// Documentation
	@inlinable
	public func write(
		_ data: [Datastream], offsets: [some BinaryInteger], relativeTo baseOffset: Offset
	) {
		let offsets = offsets.map { Int($0) + baseOffset.offest }
		
		for (offset, item) in zip(offsets, data) {
			jump(to: Offset(offset))
			write(item)
		}
	}
}

// MARK: offset
extension Datawriter {
	public struct Offset {
		@usableFromInline
		var offest: Int
		
		@inlinable
		init(_ offest: Int) {
			self.offest = offest
		}
		
		@inlinable
		public static func + (lhs: Offset, rhs: some BinaryInteger) -> Offset {
			Offset(lhs.offest + Int(rhs))
		}
	}
	
	/// Documentation
	@inlinable
	public func placeMarker() -> Offset {
		Offset(offset)
	}
}

@usableFromInline
//fileprivate let fillerByte: UInt8 = 0
internal let fillerByte: UInt8 = 0 // for inlinability

// MARK: jump
extension Datawriter {
	/// Documentation
	@inlinable
	public func jump(bytes: some BinaryInteger) {
		offset += Int(bytes)
		
		if offset > self.bytes.endIndex {
			self.bytes.append(contentsOf: [Byte](repeating: fillerByte, count: offset - self.bytes.endIndex))
		}
	}
	
	/// Documentation
	@inlinable
	public func jump(to offset: Offset) {
		self.offset = offset.offest
		
		if self.offset > bytes.endIndex {
			bytes.append(contentsOf: [Byte](repeating: fillerByte, count: self.offset - bytes.endIndex))
		}
	}
}

