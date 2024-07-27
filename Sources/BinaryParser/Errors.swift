public enum BinaryParserError: Error {
	case indexOutOfBounds(index: Int, expected: Range<Int>, for: Any.Type)
	case whileReadingFile(String, String, String, any Error) // name, fileExtension, magicBytes
	case whileReading(Any.Type, any Error)
	case whileReading(Any.Type, count: Int, any Error)
	case whileReading(Any.Type, offsets: [Int], any Error)
	case whileWriting(Any.Type, any Error)
	case whileWriting(Any.Type, count: Int, any Error)
	case whileWriting(Any.Type, offsets: [Int], any Error)
}

public enum BinaryParserAssertionError<T: Sendable>: Error {
	case unexpectedValue(actual: T, expected: T)
}
