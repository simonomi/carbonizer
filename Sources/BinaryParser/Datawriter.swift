import Foundation

final public class Datawriter {
//	public private(set) var bytes: ArraySlice<UInt8>
	public var bytes: ArraySlice<UInt8> // for inlinability
	
//	public private(set) var offset: Int
	public var offset: Int // for inlinability
	
	@inlinable
	public init() {
		bytes = []
		offset = bytes.endIndex
	}
	
	@inlinable
	public func intoDatastream() -> Datastream {
		Datastream(bytes)
	}
}

// MARK: write
extension Datawriter {
	@inlinable
	public func write(_ data: some BinaryConvertible) {
		data.write(to: self)
	}
	
	@inlinable
	public func write(_ data: some Sequence<some BinaryConvertible>) {
		data.forEach(write)
	}
	
	@inlinable
	public func write(
		_ data: [some BinaryConvertible],
		offsets: [some BinaryInteger],
		relativeTo baseOffset: Offset,
		fillerByte: UInt8 = 0
	) {
		let offsets = offsets.map { Int($0) + baseOffset.offest }
		
		for (offset, item) in zip(offsets, data) {
			jump(to: Offset(offset), fillerByte: fillerByte)
			write(item)
		}
	}
}

// MARK: primitives
extension Datawriter {
	@inlinable
	public func write(_ byte: UInt8) {
		if offset == bytes.endIndex {
			bytes.insert(byte, at: offset)
		} else {
			assert(bytes[offset].isFillerByte)
			bytes[offset] = byte
		}
		
		offset += 1
	}
	
	@inlinable
	public func write<T: FixedWidthInteger>(_ data: T) {
		let byteWidth = T.bitWidth / 8
		
		let newBytes = (0..<byteWidth)
			.map { data >> ($0 * 8) }
			.map { UInt8(truncatingIfNeeded: $0) }
		
		if offset == bytes.endIndex {
			bytes.insert(contentsOf: newBytes, at: offset)
		} else {
			let endIndex = offset + byteWidth
			assert(bytes[offset..<endIndex].allSatisfy(\.isFillerByte))
			bytes.replaceSubrange(offset..<endIndex, with: newBytes)
		}
		offset += byteWidth
	}
	
	@inlinable
	public func write(_ data: some Sequence<some FixedWidthInteger>) {
		data.forEach(write)
	}
	
	@inlinable
	public func write(_ string: String) {
		let data = string.utf8CString.map(UInt8.init)
		if offset == bytes.endIndex {
			bytes.insert(contentsOf: data, at: offset)
		} else {
			let endIndex = offset + data.count
			assert(bytes[offset..<endIndex].allSatisfy(\.isFillerByte))
			bytes.replaceSubrange(offset..<endIndex, with: data)
		}
		offset += string.utf8CString.count
	}
	
	@inlinable
	public func write(
		_ data: [String],
		offsets: [some BinaryInteger],
		relativeTo baseOffset: Offset,
		fillerByte: UInt8 = 0
	) {
		for (offset, item) in zip(offsets, data) {
			jump(to: baseOffset + offset, fillerByte: fillerByte)
			write(item)
		}
	}
	
	@inlinable
	public func write(
		_ data: [[String]],
		offsets: [[some BinaryInteger]],
		relativeTo baseOffset: Offset,
		fillerByte: UInt8 = 0
	) {
		for (offsetRow, dataRow) in zip(offsets, data) {
			for (offset, item) in zip(offsetRow, dataRow) {
				jump(to: baseOffset + offset, fillerByte: fillerByte)
				write(item)
			}
		}
	}
	
	@inlinable
	public func write(_ string: String, length: some BinaryInteger) {
		let length = Int(length)
		
		var string = string
		if string.utf8CString.count < length {
			string = string.padded(toLength: length, with: "\0", from: .trailing)
		}
		let data = string.utf8CString[..<length].map(UInt8.init)
		
		if offset == bytes.endIndex {
			bytes.insert(contentsOf: data, at: offset)
		} else {
			let endIndex = offset + data.count
			assert(bytes[offset..<endIndex].allSatisfy(\.isFillerByte))
			bytes.replaceSubrange(offset..<endIndex, with: data)
		}
		offset += length
	}
	
	@inlinable
	public func write(_ data: Datastream) {
		if offset == bytes.endIndex {
			bytes.insert(contentsOf: data.bytes[data.offset...], at: offset)
		} else {
			let endIndex = offset + data.bytes[data.offset...].count
			assert(bytes[offset..<endIndex].allSatisfy(\.isFillerByte))
			bytes.replaceSubrange(offset..<endIndex, with: data.bytes[data.offset...])
		}
		offset += data.bytes.count
	}
	
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
			assert(bytes[offset..<endIndex].allSatisfy(\.isFillerByte))
			bytes.replaceSubrange(offset..<endIndex, with: data.bytes[data.offset..<endIndex])
		}
		offset += length
	}
	
	@inlinable
	public func write(
		_ data: [Datastream],
		offsets: [some BinaryInteger],
		relativeTo baseOffset: Offset,
		fillerByte: UInt8 = 0
	) {
		let offsets = offsets.map { Int($0) + baseOffset.offest }
		
		assert(data.count == offsets.count)
		
		for (offset, item) in zip(offsets, data) {
			jump(to: Offset(offset), fillerByte: fillerByte)
			write(item)
		}
	}
	
	@inlinable
	public func write(_: ()) {}
	
	@inlinable
	@_disfavoredOverload
	public func write<T: RawRepresentable>(
		_ value: T
	) where T.RawValue: FixedWidthInteger {
		write(value.rawValue)
	}
	
	@inlinable
	@_disfavoredOverload
	public func write<T: RawRepresentable>(
		_ value: T
	) where T.RawValue: BinaryConvertible {
		write(value.rawValue)
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
	
	@inlinable
	public func placeMarker() -> Offset {
		Offset(offset)
	}
}

// MARK: jump
extension Datawriter {
	@inlinable
	public func jump(bytes: some BinaryInteger, fillerByte: UInt8 = 0) {
		offset += Int(bytes)
		
		if offset > self.bytes.endIndex {
			self.bytes.append(contentsOf: repeatElement(fillerByte, count: offset - self.bytes.endIndex))
		}
	}
	
	@inlinable
	public func jump(to offset: Offset, fillerByte: UInt8 = 0) {
		self.offset = offset.offest
		
		if self.offset > bytes.endIndex {
			bytes.append(contentsOf: repeatElement(fillerByte, count: self.offset - bytes.endIndex))
		}
	}
	
	@inlinable
	public func fourByteAlign(fillerByte: UInt8 = 0) {
		if !offset.isMultiple(of: 4) {
			jump(bytes: 4 - (offset % 4), fillerByte: fillerByte)
		}
	}
}
