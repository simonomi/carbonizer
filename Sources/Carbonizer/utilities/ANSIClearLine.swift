enum ANSIClearLine: Int {
	case clearToEndOfLine = 0
	case clearToBeginningOfLine = 1
	case clearLine = 2
}

extension DefaultStringInterpolation {
	mutating func appendInterpolation(_ variant: ANSIClearLine) {
		appendInterpolation("\u{001B}[\(variant.rawValue)K")
	}
}
