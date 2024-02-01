import SwiftSyntax

enum ArgumentParsingError: Error {
	case invalidKeyPathBase(String?)
}

enum AttributeParsingError: Error {
	case duplicateAttribute(String)
	case paddingAndOffset
}

extension Attributes {
	mutating func parseAttribute(_ attribute: AttributeSyntax) throws {
		let attributeName = attribute.attributeName.trimmedDescription
		
		let keyPaths: [String : WritableKeyPath<Self, ValueOrProperty?>] = [
			"Padding": \.padding,
			"Offset": \.offset,
			"Count": \.count,
			"Length": \.length,
			"EndOffset": \.endOffset
		]
		
		if let keyPath = keyPaths[attributeName] {
			guard self[keyPath: keyPath] == nil else {
				throw AttributeParsingError.duplicateAttribute(attributeName)
			}
			
			guard let arguments = attribute.arguments.flatMap(LabeledExprListSyntax.init),
				  !arguments.isEmpty else {
				fatalError("all attributes require arguments")
			}
			
			self[keyPath: keyPath] = try parseArgument(arguments.first!)
			
			if arguments.count > 1 {
				self[keyPath: keyPath] = applyOperator(arguments.last!, to: self[keyPath: keyPath]!)
			}
		} else if attributeName == "Offsets" {
			guard offsets == nil else {
				throw AttributeParsingError.duplicateAttribute("Offsets")
			}
			
			guard let arguments = attribute.arguments.flatMap(LabeledExprListSyntax.init) else {
				fatalError("@Offsets requires arguments")
			}
			
			offsets = try parseOffsets(arguments)
		} else if attributeName == "If" {
			guard ifCondition == nil else {
				throw AttributeParsingError.duplicateAttribute("Lengths")
			}
			
			guard let arguments = attribute.arguments.flatMap(LabeledExprListSyntax.init) else {
				fatalError("@If requires arguments")
			}
			
			ifCondition = try parseIfCondition(arguments)
		}
	}
}

func parseArgument(_ argument: LabeledExprSyntax) throws -> ValueOrProperty {
	let expression = argument.expression
	if let keyPath = KeyPathExprSyntax(expression) {
		let keyPathBase = keyPath.root?.trimmedDescription
		guard keyPathBase == "Self" else {
			throw ArgumentParsingError.invalidKeyPathBase(keyPathBase)
		}
		let path = keyPath.components.trimmedDescription
		let pathWithoutLeadingPeriod = String(path.dropFirst())
		return .property(pathWithoutLeadingPeriod)
	} else if let identifier = DeclReferenceExprSyntax(expression) {
		return .property(identifier.trimmedDescription)
	} else if let integerAsString = IntegerLiteralExprSyntax(expression)?.trimmedDescription {
		let value =
			if integerAsString.hasPrefix("0x") {
				Int(integerAsString.dropFirst(2), radix: 16)! // should never fail, right?
			} else {
				Int(integerAsString)! // may fail if octal or binary, but idc
			}
		return .value(value)
	} else {
		fatalError("the argument must be an int or a keypath")
		// this could possibly happen if its an identifier? maybe a static let?
		// oh well idc that much
	}
}

func applyOperator(_ operatorArgument: LabeledExprSyntax, to valueOrProperty: ValueOrProperty) -> ValueOrProperty {
	guard case .property(let property) = valueOrProperty else {
		fatalError("operators can only be used on properties")
	}
	
	let expression = operatorArgument.expression
	if expression.is(NilLiteralExprSyntax.self) {
		return valueOrProperty
	}
	
	guard let enumCase = FunctionCallExprSyntax(expression) else {
		fatalError("argument must be an enum case with an associated value")
	}
	
	let caseName = enumCase.calledExpression.trimmedDescription.dropFirst() // remove leading .
	
	guard let modifyingValue = IntegerLiteralExprSyntax(enumCase.arguments.first?.expression)?.trimmedDescription else {
		fatalError("associated value must be an int")
	}
	
	let operatorSymbol =
		switch caseName {
			case "plus": " + "
			case "minus": " - "
			case "times": " * "
			case "dividedBy": " / "
			case "modulo": " % "
			default: fatalError("unexpected operator")
		}
	
	return .property(property + operatorSymbol + modifyingValue)
}

func parseOffsets(_ arguments: LabeledExprListSyntax) throws -> Property.Size.Offsets {
	guard let keyPath = KeyPathExprSyntax(arguments.first!.expression) else {
		fatalError("@Offsets first argument must be a keypath")
	}
	
	let keyPathBase = keyPath.root?.trimmedDescription
	guard keyPathBase == "Self" else {
		throw ArgumentParsingError.invalidKeyPathBase(keyPathBase)
	}
	
	let path = keyPath.components.trimmedDescription
	let pathWithoutLeadingPeriod = String(path.dropFirst())
	
	switch arguments.count {
		case 1:
			return .givenByPath(pathWithoutLeadingPeriod)
		case 2:
			guard let subKeyPath = KeyPathExprSyntax(arguments.last!.expression) else {
				fatalError("@Offsets' second argument must be a keypath")
			}
			
			let subPath = subKeyPath.trimmedDescription
			
			return .givenByPathAndSubpath(pathWithoutLeadingPeriod, subPath)
		case 3:
			let secondIndex = arguments.index(after: arguments.startIndex)
			guard let startKeyPath = KeyPathExprSyntax(arguments[secondIndex].expression) else {
				fatalError("@Offsets' second argument must be a keypath")
			}
			let startPath = startKeyPath.trimmedDescription
			
			guard let endKeyPath = KeyPathExprSyntax(arguments.last!.expression) else {
				fatalError("@Offsets' third argument must be a keypath")
			}
			let endPath = endKeyPath.trimmedDescription
			
			return .givenByPathStartToEnd(pathWithoutLeadingPeriod, startPath, endPath)
		default:
			fatalError("@Offsets should only have 1 or 2 arguments")
	}
}

func parseIfCondition(_ arguments: LabeledExprListSyntax) throws -> String {
	guard arguments.count == 2 else {
		fatalError("@If requires two arguments")
	}
	
	guard let keyPath = KeyPathExprSyntax(arguments.first!.expression) else {
		fatalError("@Offsets first argument must be a keypath")
	}
	
	let keyPathBase = keyPath.root?.trimmedDescription
	guard keyPathBase == "Self" else {
		throw ArgumentParsingError.invalidKeyPathBase(keyPathBase)
	}
	
	let path = keyPath.components.trimmedDescription
	let pathWithoutLeadingPeriod = String(path.dropFirst())
	
	let (operatorSymbol, value) = try parseCondition(arguments.last!)
	
	return pathWithoutLeadingPeriod + operatorSymbol + value
}

func parseCondition(_ conditionArgument: LabeledExprSyntax) throws -> (String, String) {
	let expression = conditionArgument.expression
	
	guard let enumCase = FunctionCallExprSyntax(expression) else {
		fatalError("argument must be an enum case with an associated value")
	}
	
	let caseName = enumCase.calledExpression.trimmedDescription.dropFirst() // remove leading .
	
	guard let modifyingValue = enumCase.arguments.first?.expression.trimmedDescription else {
		fatalError("argument must have associated value")
	}
	
	let operatorSymbol =
		switch caseName {
			case "equalTo": " == "
			case "notEqualTo": " != "
			case "greaterThan": " > "
			case "lessThan": " < "
			case "greaterThanOrEqualTo": " >= "
			case "lessThanOrEqualTo": " <= "
			default: fatalError("unexpected condition")
		}
	
	return (operatorSymbol, modifyingValue)
}
