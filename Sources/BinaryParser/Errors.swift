import ANSICodes

public protocol WrappingError: Error {
	var joinedErrorPrefix: String { get }
}

public enum BinaryParserError: WrappingError, CustomStringConvertible {
	case indexOutOfBounds(index: Int, expected: Range<Int>)
	case whileReadingFile(String, any Error)
	case whileReading(Any.Type, any Error)
	case whileWriting(Any.Type, any Error)
	
	// public only for inlinability
	public static func indexOutOfBounds(index: Int, expected: Range<Int>, whileReading type: Any.Type) -> Self {
		.whileReading(type, Self.indexOutOfBounds(index: index, expected: expected))
	}
	
	public var joinedErrorPrefix: String {
		switch self {
			case .indexOutOfBounds: ": "
			case .whileReadingFile, .whileReading, .whileWriting: ">"
		}
	}
	
	public var description: String {
		switch self {
			case .indexOutOfBounds(let index, let expected):
				"index \(.red)\(index)\(.normal) out of bounds, expected \(.green)\(expected)\(.normal)"
			case .whileReadingFile(let name, let error as WrappingError):
				if case Self.whileReadingFile = error {
					"\(.bold)\(name)\(.normal)/\(error)"
				} else {
					"\(.bold)\(name)\(.normal)\(error.joinedErrorPrefix)\(error)"
				}
			case .whileReadingFile(let name, let error):
				"\(.bold)\(name)\(.normal): \(error)"
			case .whileReading(let any, let error as WrappingError):
				"\(.bold)\(String(almostFullyQualified: any))\(.normal)\(error.joinedErrorPrefix)\(error)"
			case .whileReading(let any, let error):
				"\(.bold)\(String(almostFullyQualified: any))\(.normal): \(error)"
			case .whileWriting(let any, let error as WrappingError):
				// TODO: indicate writing?
				"\(.bold)\(String(almostFullyQualified: any))\(.normal)\(error.joinedErrorPrefix)\(error)"
			case .whileWriting(let any, let error):
				// TODO: indicate writing?
				"\(.bold)\(String(almostFullyQualified: any))\(.normal): \(error)"
		}
	}
}

public struct BinaryParserAssertionError<T: Sendable>: WrappingError, CustomStringConvertible {
	var expected: T
	var actual: T
	var property: String
	
	public init(expected: T, actual: T, property: String) {
		self.expected = expected
		self.actual = actual
		self.property = property
	}
	
	public var joinedErrorPrefix: String { "." }
	
	public var description: String {
		"\(.cyan)\(.bold)\(property)\(.normal): expected \(.green)'\(expected)'\(.normal), got \(.red)'\(actual)'\(.normal)"
	}
}
