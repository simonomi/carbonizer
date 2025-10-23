import ANSICodes

public struct InvalidRawValue<T: RawRepresentable>: Error {
	var raw: T.RawValue
	
	public init(_ raw: T.RawValue, for _: T.Type) {
		self.raw = raw
	}
}

extension InvalidRawValue: Sendable where T.RawValue: Sendable {}

extension InvalidRawValue: CustomStringConvertible {
	public var description: String {
		"invalid raw value for type \(T.self): \(.red)\(raw)\(.normal)"
	}
}
