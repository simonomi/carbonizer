public struct ANSIMoveToColumn: Sendable {
	var column: Int
	
	static let moveToStartOfLine = Self(column: 1)
	
	static func moveTo(column: Int) -> Self {
		Self(column: column)
	}
}

public extension DefaultStringInterpolation {
	mutating func appendInterpolation(_ moveToColumn: ANSIMoveToColumn) {
		appendInterpolation("\u{001B}[\(moveToColumn.column)G")
	}
}
