extension Property {
	func makeInitialization() -> String {
		let (ifCheck, endIfCheck) = 
			if let ifCondition {
				("if \(ifCondition) {\n\t", "\n}")
			} else {
				("", "")
			}
		
		let setOffset = 
			if let offset {
				"data.jump(to: base + \(offset.value))\n"
			} else if let padding {
				"data.jump(bytes: \(padding.value))\n"
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
				", endOffset: \(endOffset.value), relativeTo: base"
			} else {
				""
			}
		
		let declarationKeyword = if isStatic {
			"let "
		} else {
			""
		}
		
		let dataRead =
		switch size {
			case .auto:
				"\(declarationKeyword)\(name) = try data.read(\(type).self\(lengthArgument)\(endOffsetAndRelativeTo))"
				
			case .count(let count):
				"\(declarationKeyword)\(name) = try data.read(\(type).self, count: \(count.value))"
				
			case .offsets(.givenByPath(let path)):
				"\(declarationKeyword)\(name) = try data.read(\(type).self, offsets: \(path)\(endOffsetArgument), relativeTo: base)"
				
			case .offsets(.givenByPathAndSubpath(let path, let subPath)):
				"\(declarationKeyword)\(name) = try data.read(\(type).self, offsets: \(path).map(\(subPath))\(endOffsetArgument), relativeTo: base)"
				
			case .offsets(.givenByPathStartToEnd(let path, let startPath, let endPath)):
				"\(declarationKeyword)\(name) = try data.read(\(type).self, startOffsets: \(path).map(\(startPath)), endOffsets: \(path).map(\(endPath)), relativeTo: base)"
		}
		
		let assertExpected = 
			if let expected {
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
	
	func makeWriter() -> String {
		let (ifCheck, endIfCheck) =
			if let ifCondition {
				("if \(ifCondition), let \(name) {\n\t", "\n}")
			} else {
				("", "")
			}
		
		let setOffset =
			if let offset {
				"data.jump(to: base + \(offset.value))\n"
			} else if let padding {
				"data.jump(bytes: \(padding.value))\n"
			} else {
				""
			}
		
		let lengthArgument =
			if let length {
				", length: \(length.value)"
			} else {
				""
			}
		
		let selfDot = if isStatic {
				"Self."
			} else {
				"" // could be "self."?
			}
		
		let dataWrite =
			switch size {
				case .auto, .count:
					"data.write(\(selfDot)\(name)\(lengthArgument))"
				
				case .offsets(.givenByPath(let path)):
					"data.write(\(selfDot)\(name), offsets: \(path), relativeTo: base)"
				
				case .offsets(.givenByPathAndSubpath(let path, let subPath)),
					 .offsets(.givenByPathStartToEnd(let path, let subPath, _)):
					"data.write(\(selfDot)\(name), offsets: \(path).map(\(subPath)), relativeTo: base)"
			}
		
		return ifCheck + setOffset + dataWrite + endIfCheck
	}
}
