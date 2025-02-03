public enum BinaryParserError: Error, CustomStringConvertible {
	case indexOutOfBounds(index: Int, expected: Range<Int>)
	case whileReadingFile(String, any Error)
	case whileReading(Any.Type, any Error)
	case whileWriting(Any.Type, any Error)
	
	// public only for inlinability
	public static func indexOutOfBounds(index: Int, expected: Range<Int>, whileReading type: Any.Type) -> Self {
		.whileReading(type, Self.indexOutOfBounds(index: index, expected: expected))
	}
	
	var isWrapper: Bool {
		switch self {
			case .indexOutOfBounds: false
			case .whileReadingFile, .whileReading, .whileWriting: true
		}
	}
	
	public var description: String {
		switch self {
			case .indexOutOfBounds(let index, let expected):
				"index \(.red)\(index)\(.normal) out of bounds, expected \(.green)\(expected)\(.normal)"
			case .whileReadingFile(let name, let error as BinaryParserError) where error.isWrapper:
				if case .whileReadingFile = error {
					"\(.bold)\(name)\(.normal)/\(error)"
				} else {
					"\(.bold)\(name)\(.normal)>\(error)"
				}
			case .whileReadingFile(let name, let error):
				"\(.bold)\(name)\(.normal): \(error)"
			case .whileReading(let any, let error as BinaryParserError) where error.isWrapper:
				"\(.bold)\(String(almostFullyQualified: any))\(.normal)>\(error)"
			case .whileReading(let any, let error):
				"\(.bold)\(String(almostFullyQualified: any))\(.normal): \(error)"
			case .whileWriting(let any, let error as BinaryParserError) where error.isWrapper:
				// TODO: indicate writing?
				"\(.bold)\(String(almostFullyQualified: any))\(.normal)>\(error)"
			case .whileWriting(let any, let error):
				// TODO: indicate writing?
				"\(.bold)\(String(almostFullyQualified: any))\(.normal): \(error)"
		}
	}
}

public struct BinaryParserAssertionError<T: Sendable>: Error, CustomStringConvertible {
	var expected: T
	var actual: T
	var location: String
	
	public init(
		expected: T,
		actual: T,
		fileId: String = #fileID,
		line: Int = #line,
		column: Int = #column
	) {
		self.expected = expected
		self.actual = actual
		location = "\(fileId):\(line):\(column)"
	}
	
	public var description: String {
		"\(.cyan)\(location)\(.normal): expected \(.green)'\(expected)'\(.normal), got \(.red)'\(actual)'\(.normal)"
	}
}
