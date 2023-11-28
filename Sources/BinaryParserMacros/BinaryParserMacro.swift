import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct BinaryConvertibleMacro: ExtensionMacro {
	enum BinaryConvertibleMacroError: Error, CustomStringConvertible {
		case invalidType
		
		var description: String {
			switch self {
				case .invalidType: "Invalid type"
			}
		}
	}
	
	static func expansion(
		of node: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [ExtensionDeclSyntax] {
		guard let structDecl = StructDeclSyntax(declaration) else {
			throw BinaryConvertibleMacroError.invalidType
		}
		let structName = structDecl.name.trimmedDescription.lowercased()
		
		let variableDecls = structDecl.memberBlock.members
			.map(\.decl)
			.compactMap(VariableDeclSyntax.init)
		
		let properties = try parseProperties(variableDecls)
		
		let initialization = properties
			.map { $0.makeInitialization(in: structName) }
			.joined(separator: "\n")
		
		let markerDefinition =
		if initialization.contains("try data.jump(to: \(structName) + ") ||
		   initialization.contains(", relativeTo: ") {
				"let \(structName) = data.placeMarker()\n\t\t"
			} else {
				""
			}
		
		return [try ExtensionDeclSyntax(
			"""
			extension \(type): BinaryConvertible {
				public init(_ data: Datastream) throws {
					\(raw: markerDefinition)\(raw: initialization)
				}
			}
			"""
		)]
	}
}

struct EmptyMacro: PeerMacro {
	static func expansion(
		of node: AttributeSyntax,
		providingPeersOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] { [] }
}

@main
struct BinaryParserPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
		BinaryConvertibleMacro.self,
		EmptyMacro.self
	]
}
