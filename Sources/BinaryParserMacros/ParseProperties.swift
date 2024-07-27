import SwiftSyntax

enum PropertyParsingError: Error {
	case missingCount(for: String)
	case cannotInferType(for: String, String)
	case typeShouldBeOptional(for: String, String)
	case missingEndOffset(for: String)
	case lengthOnNonString(for: String, String)
	case missingLength(for: String)
}

func parseProperties(_ declarations: [VariableDeclSyntax]) throws -> [Property] {
	try declarations.flatMap(parseProperty)
}

func parseProperty(_ declaration: VariableDeclSyntax) throws -> [Property] {
	let isStatic = declaration.modifiers.contains(where: { $0.name.trimmedDescription == "static" })
	
	let hasInclude = declaration.attributes
		.compactMap(AttributeSyntax.init)
		.map(\.attributeName.trimmedDescription)
		.contains("Include")
	
	// skip static properties unless they have `@Include`
	if isStatic, !hasInclude { return [] }
	
	let attributes = try Attributes(from: declaration.attributes, isStatic: isStatic)
	return try parseBindings(declaration.bindings, with: attributes)
}
