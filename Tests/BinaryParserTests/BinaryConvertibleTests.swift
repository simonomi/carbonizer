import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import BinaryParserMacros

let testMacros = ["binaryFile": BinaryConvertibleMacro.self]

final class BinaryConvertibleTests: XCTestCase {
//	func testSomething() {
//		assertMacroExpansion("test", expandedSource: "test", macros: testMacros)
//	}
}
// TODO: test zero-sized struct
