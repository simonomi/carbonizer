import Foundation

extension [any CodingKey] {
	func formatted() -> String {
		reduce("") { partialResult, key in
			if partialResult.isEmpty {
				if let index = key.intValue {
					"[\(index)]"
				} else {
					key.stringValue
				}
			} else if let index = key.intValue {
				"\(partialResult)[\(index)]"
			} else {
				"\(partialResult).\(key.stringValue)"
			}
		}
	}
}

extension DecodingError {
	func configurationFormatting(path: URL) -> String {
		switch self {
			case .typeMismatch(let expectedType, let context):
				let fullKeyPath = context.codingPath
				
				return "\(path.path(percentEncoded: false))>\(fullKeyPath.formatted()): invalid type, expected \(expectedType)"
			case .keyNotFound(let key, let context):
				let fullKeyPath = context.codingPath + [key]
				
				return "\(path.path(percentEncoded: false))>\(fullKeyPath.formatted()): missing value for option"
			default:
				return "\(path.path(percentEncoded: false)): \(self)"
		}
	}
}
