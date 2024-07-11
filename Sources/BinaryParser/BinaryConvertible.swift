import Foundation

public protocol BinaryConvertible {
	init(_ data: Datastream) throws
	func write(to data: Datawriter)
}

extension Datastream {
	@inlinable
	public func write(to data: Datawriter) {
		data.write(self)
	}
}

extension String: BinaryConvertible {
	@inlinable
	public init(_ data: Datastream) throws {
		self = try data.read(String.self)
	}
	
	@inlinable
	public func write(to data: Datawriter) {
		data.write(self)
	}
}
