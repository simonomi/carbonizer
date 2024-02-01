import XCTest
import SwiftSyntax

@testable import BinaryParserMacros

func assert(declarations: String, parseTo expectedResults: [Property?]) {
	let declarations = declarations
		.split(separator: "\n")
		.map(String.init)
	
	XCTAssertEqual(declarations.count, expectedResults.count)
	
	for (declaration, expectedResult) in zip(declarations, expectedResults) {
		assert(declaration: declaration, parsesTo: expectedResult)
	}
}

func assert(declaration: String, parsesTo expectedResult: Property?) {
	guard let declaration = VariableDeclSyntax(DeclSyntax(stringLiteral: declaration)) else {
		return XCTFail("declaration does not parse")
	}
	
	let actualResult: Property?
	do {
		actualResult = try parseProperty(declaration).first
	} catch {
		return XCTFail("unexpected error \(error)")
	}
	
	XCTAssertEqual(String(reflecting: expectedResult), String(reflecting: actualResult))
}

func assert(declarations: String, throw expectedErrors: [Error]) {
	let declarations = declarations
		.split(separator: "\n")
		.map(String.init)
	
	XCTAssertEqual(declarations.count, expectedErrors.count)
	
	for (declaration, expectedError) in zip(declarations, expectedErrors) {
		assert(declaration: declaration, throws: expectedError)
	}
}
	
func assert(declaration: String, throws expectedError: Error) {
	guard let declaration = VariableDeclSyntax(DeclSyntax(stringLiteral: declaration)) else {
		return XCTFail("declaration does not parse")
	}
	
	XCTAssertThrowsError(try parseProperty(declaration)) { actualError in
		XCTAssertEqual(String(reflecting: expectedError), String(reflecting: actualError))
	}
}

final class ParsePropertiesTests: XCTestCase {
	func testIgnoresStaticProperties() {
		assert(
			declarations: #"""
				static var int: UInt32
				static var string: String
				static var otherType: OtherType
				"""#,
			parseTo: [nil, nil, nil]
		)
	}
	
	func testIgnoresComputedProperties() {
		assert(
			declarations: #"""
				var int: UInt32 {}
				var string: String {}
				var otherType: OtherType {}
				"""#,
			parseTo: [nil, nil, nil]
		)
	}
	
	func testVariousStrings() {
		assert(
			declarations: #"""
				var string: String
				@Length(4) var string: String
				@Length(\Self.stringLength) var string: String
				var string = "hi"
				"""#,
			parseTo: [
				Property(name: "string", type: "String", size: .auto),
				Property(name: "string", type: "String", size: .auto, length: 4),
				Property(name: "string", type: "String", size: .auto, length: "stringLength"),
				Property(name: "string", type: "String", size: .auto, expected: #""hi""#)
			]
		)
	}
	
	func testPadding() {
		assert(
			declarations: "@Padding(2) var padded: UInt32",
			parseTo: [
				Property(name: "padded", type: "UInt32", size: .auto, padding: .value(2))
			]
		)
	}
	
	func testDuplicateAttributes() {
		assert(
			declarations: #"""
				@Count(4) @Count(7) var string = "hi"
				@Count(4) @Count(4) var string = "hi"
				"""#,
			throw: [
				AttributeParsingError.duplicateAttribute("Count"),
				AttributeParsingError.duplicateAttribute("Count")
			]
		)
	}
	
	func testInts() {
		assert(
			declarations: """
				var uint8: UInt8
				var uint16: UInt16
				var uint32: UInt32
				var uint64: UInt64
				var int8: Int8
				var int16: Int16
				var int32: Int32
				var int64: Int64
				""",
			parseTo: [
				Property(name: "uint8", type: "UInt8", size: .auto),
				Property(name: "uint16", type: "UInt16", size: .auto),
				Property(name: "uint32", type: "UInt32", size: .auto),
				Property(name: "uint64", type: "UInt64", size: .auto),
				Property(name: "int8", type: "Int8", size: .auto),
				Property(name: "int16", type: "Int16", size: .auto),
				Property(name: "int32", type: "Int32", size: .auto),
				Property(name: "int64", type: "Int64", size: .auto)
			]
		)
	}
	
	func testArrayOfUInt32() {
		assert(
			declarations: #"""
				@Count(10) var uint32s: [UInt32]
				@Count(\Self.count) var uint32s: [UInt32]
				"""#,
			parseTo: [
				Property(name: "uint32s", type: "[UInt32]", size: .count(10)),
				Property(name: "uint32s", type: "[UInt32]", size: .count("count"))
			]
		)
	}
	
	func testArrayWithoutCount() {
		assert(
			declarations: """
				var uint32s: [UInt32]
				var data: [Data]
				""",
			throw: [
				PropertyParsingError.missingCount(for: "uint32s"),
				PropertyParsingError.missingCount(for: "data")
			]
		)
	}
	
	func testIfCondition() {
		assert(
			declaration: #"@If(\Self.test, is: .equalTo(1)) var string: String"#,
			throws: PropertyParsingError.typeShouldBeOptional(for: "string", "String")
		)
		assert(
			declarations: #"""
				@If(\Self.test, is: .equalTo(1)) var string1: String?
				@If(\Self.test, is: .lessThan(1)) var string2: String?
				@If(\Self.test, is: .greaterThan(1)) var string3: String?
				@If(\Self.test, is: .lessThanOrEqualTo(1)) var string4: String?
				@If(\Self.test, is: .greaterThanOrEqualTo(1)) var string5: String?
				"""#,
			parseTo: [
				Property(name: "string1", type: "String", size: .auto, ifCondition: "test == 1"),
				Property(name: "string2", type: "String", size: .auto, ifCondition: "test < 1"),
				Property(name: "string3", type: "String", size: .auto, ifCondition: "test > 1"),
				Property(name: "string4", type: "String", size: .auto, ifCondition: "test <= 1"),
				Property(name: "string5", type: "String", size: .auto, ifCondition: "test >= 1")
			]
		)
	}
	
	func testEndOffset() {
		assert(
			declaration: "@Count(1) var data: [Data]",
			throws: PropertyParsingError.missingEndOffset(for: "data")
		)
		assert(
			declarations: #"""
				@EndOffset(givenBy: \Self.endOffset) @Count(1) var data1: [Data]
				@EndOffset(7) @Count(1) var data2: [Data]
				"""#,
			parseTo: [
				Property(name: "data1", type: "[Data]", size: .count(1), endOffset: "endOffset"),
				Property(name: "data2", type: "[Data]", size: .count(1), endOffset: 7)
			]
		)
	}
	
	func testDTX() {
		assert(
			declarations: #"""
				var magicBytes = "DTX"
				var stringCount: UInt32
				var indexesOffset: UInt32
				@Offset(givenBy: \Self.indexesOffset) @Count(givenBy: \Self.stringCount) var indexes: [UInt32]
				@Offsets(givenBy: \Self.indexes) var strings: [String]
				"""#,
			parseTo: [
				Property(name: "magicBytes", type: "String", size: .auto, expected: #""DTX""#),
				Property(name: "stringCount", type: "UInt32", size: .auto),
				Property(name: "indexesOffset", type: "UInt32", size: .auto),
				Property(name: "indexes", type: "[UInt32]", size: .count("stringCount"), offset: .property("indexesOffset")),
				Property(name: "strings", type: "[String]", size: .offsets(.givenByPath("indexes")))
			]
		)
	}
	
	func testMM3() {
		assert(
			declarations: #"""
				var magicBytes = "MM3"
				var index1: UInt32
				var tableFileName1Offset: UInt32
				var index2: UInt32
				var tableFileName2Offset: UInt32
				var index3: UInt32
				var tableFileName3Offset: UInt32
				@Offset(givenBy: \Self.tableFileName1Offset) var tableFileName1: String
				@Offset(givenBy: \Self.tableFileName2Offset) var tableFileName2: String
				@Offset(givenBy: \Self.tableFileName3Offset) var tableFileName3: String
				"""#,
			parseTo: [
				Property(name: "magicBytes", type: "String", size: .auto, expected: #""MM3""#),
				Property(name: "index1", type: "UInt32", size: .auto),
				Property(name: "tableFileName1Offset", type: "UInt32", size: .auto),
				Property(name: "index2", type: "UInt32", size: .auto),
				Property(name: "tableFileName2Offset", type: "UInt32", size: .auto),
				Property(name: "index3", type: "UInt32", size: .auto),
				Property(name: "tableFileName3Offset", type: "UInt32", size: .auto),
				Property(name: "tableFileName1", type: "String", size: .auto, offset: .property("tableFileName1Offset")),
				Property(name: "tableFileName2", type: "String", size: .auto, offset: .property("tableFileName2Offset")),
				Property(name: "tableFileName3", type: "String", size: .auto, offset: .property("tableFileName3Offset"))
			]
		)
		assert(
			declarations: #"""
				var magicBytes = "MM3"
				var index1: UInt32
				var tableFileName1Offset: UInt32
				var index2: UInt32
				var tableFileName2Offset: UInt32
				var index3: UInt32
				var tableFileName3Offset: UInt32
				@Offset(givenBy: \Self.tableFileName1Offset) var tableFileName1: String
				@Offset(givenBy: \Self.tableFileName2Offset) var tableFileName2: String
				@Offset(givenBy: \Self.tableFileName3Offset) var tableFileName3: String
				"""#,
			parseTo: [
				Property(name: "magicBytes", type: "String", size: .auto, expected: #""MM3""#),
				Property(name: "index1", type: "UInt32", size: .auto),
				Property(name: "tableFileName1Offset", type: "UInt32", size: .auto),
				Property(name: "index2", type: "UInt32", size: .auto),
				Property(name: "tableFileName2Offset", type: "UInt32", size: .auto),
				Property(name: "index3", type: "UInt32", size: .auto),
				Property(name: "tableFileName3Offset", type: "UInt32", size: .auto),
				Property(name: "tableFileName1", type: "String", size: .auto, offset: .property("tableFileName1Offset")),
				Property(name: "tableFileName2", type: "String", size: .auto, offset: .property("tableFileName2Offset")),
				Property(name: "tableFileName3", type: "String", size: .auto, offset: .property("tableFileName3Offset"))
			]
		)
	}
}
