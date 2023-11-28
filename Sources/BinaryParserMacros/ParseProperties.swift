//
//  PropertyParser.swift
//
//
//  Created by alice on 2023-11-12.
//

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
	// ignore static properties
	if declaration.modifiers.contains(where: { $0.name.trimmedDescription == "static" }) { return [] }
	
	let attributes = try Attributes(from: declaration.attributes)
	return try parseBindings(declaration.bindings, with: attributes)
}
