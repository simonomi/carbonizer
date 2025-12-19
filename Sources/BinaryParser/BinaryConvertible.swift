import Foundation

public typealias ByteSlice = ArraySlice<UInt8>

public protocol BinaryConvertible {
	init(_ data: inout Datastream) throws
	func write(to data: Datawriter)
}

extension Data: BinaryConvertible {
	public init(_ data: inout Datastream) {
		self = data.read(Self.self)
	}
	
	public func write(to data: Datawriter) {
		data.write(self)
	}
}

extension ByteSlice: BinaryConvertible {
	public init(_ data: inout Datastream) {
		self = data.read(Self.self)
	}
	
	public func write(to data: Datawriter) {
		data.write(self)
	}
}
