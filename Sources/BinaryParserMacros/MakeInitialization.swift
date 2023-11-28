//
//  MakeInitialization.swift
//
//
//  Created by alice on 2023-11-12.
//

extension Property {
	func makeInitialization(in structName: String) -> String {
		let (ifCheck, endIfCheck) = if let ifCondition {
				("if \(ifCondition) {\n\t", "\n}")
			} else {
				("", "")
			}
		
		let setOffset = if let offset {
				"try data.jump(to: \(structName) + \(offset.value))\n"
			} else if let padding {
				"try data.jump(bytes: \(padding.value))\n"
			} else {
				""
			}
		
		let lengthArgument =
			if let length {
				", length: \(length.value)"
			} else {
				""
			}
		
		let endOffsetArgument =
			if let endOffset {
				", endOffset: \(endOffset.value)"
			} else {
				""
			}
		
		let endOffsetAndRelativeTo =
			if let endOffset {
				", endOffset: \(endOffset.value), relativeTo: \(structName)"
			} else {
				""
			}
		
		let dataRead = switch size {
			case .auto:
				"\(name) = try data.read(\(type).self\(lengthArgument)\(endOffsetAndRelativeTo))"
			
			case .count(let count):
				"\(name) = try data.read(\(type).self, count: \(count.value))"
			
			case .offsets(.givenByPath(let path)):
				"\(name) = try data.read(\(type).self, offsets: \(path)\(endOffsetArgument), relativeTo: \(structName))"
			
			case .offsets(.givenByPathAndSubpath(let path, let subPath)):
				"\(name) = try data.read(\(type).self, offsets: \(path).map(\(subPath))\(endOffsetArgument), relativeTo: \(structName))"
			
			case .offsets(.givenByPathStartToEnd(let path, let startPath, let endPath)):
				"\(name) = try data.read(\(type).self, startOffsets: \(path).map(\(startPath)), endOffsets: \(path).map(\(endPath)), relativeTo: \(structName))"
		}
		
		let assertExpected = if let expected {
				"""
				\nguard \(name) == \(expected) else {
					throw BinaryParserAssertionError.unexpectedValue(actual: \(name), expected: \(expected))
				}
				"""
			} else {
				""
			}
		
		return ifCheck + setOffset + dataRead + assertExpected + endIfCheck
	}
}
