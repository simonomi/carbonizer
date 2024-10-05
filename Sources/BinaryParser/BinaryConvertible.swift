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
