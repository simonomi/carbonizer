import Foundation

final public class Datawriter {
	public typealias Byte = UInt8
	
	public private(set) var bytes: ArraySlice<Byte>
	public private(set) var offset: Int
	
	public init() {
		bytes = []
		offset = bytes.endIndex
	}
	
	public init(capacity: Int) {
		bytes = []
		bytes.reserveCapacity(capacity)
		offset = bytes.endIndex
	}
	
	public func intoDatastream() -> Datastream {
		Datastream(bytes)
	}
}

// MARK: write
extension Datawriter {
	/// Documentation
	public func write<T: BinaryConvertible>(_ data: T) {
		data.write(to: self)
	}
	
	/// Documentation
	public func write<S: Sequence<T>, T: BinaryConvertible>(_ data: S) {
		data.forEach(write)
	}
	
	/// Documentation
	public func write<T: BinaryConvertible, U: BinaryInteger>(
		_ data: [T], offsets: [U], relativeTo baseOffset: Offset
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
	public func write<T: BinaryInteger>(_ data: T) {
		let byteWidth = data.bitWidth / 8
		
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
	public func write<S: Sequence<T>, T: BinaryInteger>(_ data: S) {
		data.forEach(write)
	}
	
	/// Documentation
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
	public func write<T: BinaryInteger>(_ string: String, length: T) {
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
	public func write<T: BinaryInteger>(
		_ data: Datastream, length: T
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
	public func write<T: BinaryInteger>(
		_ data: [Datastream], offsets: [T], relativeTo baseOffset: Offset
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

fileprivate let fillerByte: UInt8 = 0
// MARK: jump
extension Datawriter {
	/// Documentation
	public func jump<T: BinaryInteger>(bytes: T) {
		offset += Int(bytes)
		
		if offset > self.bytes.endIndex {
			self.bytes.append(contentsOf: [Byte](repeating: fillerByte, count: offset - self.bytes.endIndex))
		}
	}
	
	/// Documentation
	public func jump(to offset: Offset) {
		self.offset = offset.offest
		
		if self.offset > bytes.endIndex {
			bytes.append(contentsOf: [Byte](repeating: fillerByte, count: self.offset - bytes.endIndex))
		}
	}
}

