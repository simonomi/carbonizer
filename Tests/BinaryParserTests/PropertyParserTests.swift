import Testing
import SwiftSyntax

@testable import BinaryParserMacros

func assert(declarations: String, parseTo expectedResults: [[Property]]) throws {
	let declarations = declarations
		.split(separator: "\n")
		.map(String.init)
	
	try #require(declarations.count == expectedResults.count)
	
	for (declaration, expectedResult) in zip(declarations, expectedResults) {
		try assert(declaration: declaration, parsesTo: expectedResult)
	}
}

func assert(declaration: String, parsesTo expectedResult: [Property]) throws {
	let declaration = try #require(VariableDeclSyntax(DeclSyntax(stringLiteral: declaration)))
	
	let actualResult = try parseProperty(declaration)
	
	try #require(String(reflecting: expectedResult) == String(reflecting: actualResult))
}

func assert(declarations: String, throw expectedErrors: [Error]) throws {
	let declarations = declarations
		.split(separator: "\n")
		.map(String.init)
	
	try #require(declarations.count == expectedErrors.count)
	
	for (declaration, expectedError) in zip(declarations, expectedErrors) {
		try assert(declaration: declaration, throws: expectedError)
	}
}

func assert(declaration: String, throws expectedError: Error) throws {
	let declaration = try #require(VariableDeclSyntax(DeclSyntax(stringLiteral: declaration)))
	
	try #require {
		try parseProperty(declaration)
	} throws: { actualError in
		String(reflecting: expectedError) == String(reflecting: actualError)
	}
}

@Suite("Parse Properties")
struct PropertyParserTests {
	@Test
	func ignoresStaticProperties() throws {
		try assert(
			declarations: #"""
			   static var int: UInt32
			   static var string: String
			   static var otherType: OtherType
			   """#,
			parseTo: [[], [], []]
		)
	}
	
	@Test
	func ignoresStaticPropertiesUnlessIncluded() throws {
		try assert(
			declarations: #"""
			   @Include static var int: UInt32
			   @Include static var string: String
			   @Include static var otherType: OtherType
			   """#,
			parseTo: [
				[Property(name: "int", type: "UInt32", size: .auto, isStatic: true)],
				[Property(name: "string", type: "String", size: .auto, isStatic: true)],
				[Property(name: "otherType", type: "OtherType", size: .auto, isStatic: true)]
			]
		)
	}
	
	@Test
	func ignoresComputedProperties() throws {
		try assert(
			declarations: #"""
			   var int: UInt32 {}
			   var string: String {}
			   var otherType: OtherType {}
			   """#,
			parseTo: [[], [], []]
		)
	}
	
	@Test
	func variousStrings() throws {
		try assert(
			declarations: #"""
			   var string: String
			   @Length(4) var string: String
			   @Length(\Self.stringLength) var string: String
			   var string = "hi"
			   """#,
			parseTo: [
				[Property(name: "string", type: "String", size: .auto, isStatic: false)],
				[Property(name: "string", type: "String", size: .auto, isStatic: false, length: 4)],
				[Property(name: "string", type: "String", size: .auto, isStatic: false, length: "stringLength")],
				[Property(name: "string", type: "String", size: .auto, isStatic: false, expected: #""hi""#)]
			]
		)
	}
	
	@Test
	func padding() throws {
		try assert(
			declarations: "@Padding(2) var padded: UInt32",
			parseTo: [
				[Property(name: "padded", type: "UInt32", size: .auto, isStatic: false, padding: .value(2))]
			]
		)
	}
	
	@Test
	func duplicateAttributes() throws {
		try assert(
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
	
	@Test
	func ints() throws {
		try assert(
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
				[Property(name: "uint8", type: "UInt8", size: .auto, isStatic: false)],
				[Property(name: "uint16", type: "UInt16", size: .auto, isStatic: false)],
				[Property(name: "uint32", type: "UInt32", size: .auto, isStatic: false)],
				[Property(name: "uint64", type: "UInt64", size: .auto, isStatic: false)],
				[Property(name: "int8", type: "Int8", size: .auto, isStatic: false)],
				[Property(name: "int16", type: "Int16", size: .auto, isStatic: false)],
				[Property(name: "int32", type: "Int32", size: .auto, isStatic: false)],
				[Property(name: "int64", type: "Int64", size: .auto, isStatic: false)]
			]
		)
	}
	
	@Test
	func arrayOfUInt32() throws {
		try assert(
			declarations: #"""
			   @Count(10) var uint32s: [UInt32]
			   @Count(\Self.count) var uint32s: [UInt32]
			   """#,
			parseTo: [
				[Property(name: "uint32s", type: "[UInt32]", size: .count(10), isStatic: false)],
				[Property(name: "uint32s", type: "[UInt32]", size: .count("count"), isStatic: false)]
			]
		)
	}
	
	@Test
	func arrayWithoutCount() throws {
		try assert(
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
	
	@Test
	func ifCondition() throws {
		try assert(
			declaration: #"@If(\Self.test, is: .equalTo(1)) var string: String"#,
			throws: PropertyParsingError.typeShouldBeOptional(for: "string", "String")
		)
		try assert(
			declarations: #"""
				@If(\Self.test, is: .equalTo(1)) var string1: String?
				@If(\Self.test, is: .lessThan(1)) var string2: String?
				@If(\Self.test, is: .greaterThan(1)) var string3: String?
				@If(\Self.test, is: .lessThanOrEqualTo(1)) var string4: String?
				@If(\Self.test, is: .greaterThanOrEqualTo(1)) var string5: String?
				"""#,
			parseTo: [
				[Property(name: "string1", type: "String", size: .auto, isStatic: false, ifCondition: "test == 1")],
				[Property(name: "string2", type: "String", size: .auto, isStatic: false, ifCondition: "test < 1")],
				[Property(name: "string3", type: "String", size: .auto, isStatic: false, ifCondition: "test > 1")],
				[Property(name: "string4", type: "String", size: .auto, isStatic: false, ifCondition: "test <= 1")],
				[Property(name: "string5", type: "String", size: .auto, isStatic: false, ifCondition: "test >= 1")]
			]
		)
	}
	
	@Test
	func endOffset() throws {
		try assert(
			declaration: "@Count(1) var data: [Datastream]",
			throws: PropertyParsingError.missingEndOffset(for: "data")
		)
		try assert(
			declarations: #"""
				@EndOffset(givenBy: \Self.endOffset) @Count(1) var data1: [Data]
				@EndOffset(7) @Count(1) var data2: [Data]
				"""#,
			parseTo: [
				[Property(name: "data1", type: "[Data]", size: .count(1), isStatic: false, endOffset: "endOffset")],
				[Property(name: "data2", type: "[Data]", size: .count(1), isStatic: false, endOffset: 7)]
			]
		)
	}
	
	@Test
	func dTX() throws {
		try assert(
			declarations: #"""
				var magicBytes = "DTX"
				var stringCount: UInt32
				var indicesOffset: UInt32
				@Offset(givenBy: \Self.indicesOffset) @Count(givenBy: \Self.stringCount) var indices: [UInt32]
				@Offsets(givenBy: \Self.indices) var strings: [String]
				"""#,
			parseTo: [
				[Property(name: "magicBytes", type: "String", size: .auto, isStatic: false, expected: #""DTX""#)],
				[Property(name: "stringCount", type: "UInt32", size: .auto, isStatic: false)],
				[Property(name: "indicesOffset", type: "UInt32", size: .auto, isStatic: false)],
				[Property(name: "indices", type: "[UInt32]", size: .count("stringCount"), isStatic: false, offset: .property("indicesOffset"))],
				[Property(name: "strings", type: "[String]", size: .offsets(.givenByPath("indices")), isStatic: false)]
			]
		)
	}
	
	@Test
	func mM3() throws {
		try assert(
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
				[Property(name: "magicBytes", type: "String", size: .auto, isStatic: false, expected: #""MM3""#)],
				[Property(name: "index1", type: "UInt32", size: .auto, isStatic: false)],
				[Property(name: "tableFileName1Offset", type: "UInt32", size: .auto, isStatic: false)],
				[Property(name: "index2", type: "UInt32", size: .auto, isStatic: false)],
				[Property(name: "tableFileName2Offset", type: "UInt32", size: .auto, isStatic: false)],
				[Property(name: "index3", type: "UInt32", size: .auto, isStatic: false)],
				[Property(name: "tableFileName3Offset", type: "UInt32", size: .auto, isStatic: false)],
				[Property(name: "tableFileName1", type: "String", size: .auto, isStatic: false, offset: .property("tableFileName1Offset"))],
				[Property(name: "tableFileName2", type: "String", size: .auto, isStatic: false, offset: .property("tableFileName2Offset"))],
				[Property(name: "tableFileName3", type: "String", size: .auto, isStatic: false, offset: .property("tableFileName3Offset"))]
			]
		)
		try assert(
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
				[Property(name: "magicBytes", type: "String", size: .auto, isStatic: false, expected: #""MM3""#)],
				[Property(name: "index1", type: "UInt32", size: .auto, isStatic: false)],
				[Property(name: "tableFileName1Offset", type: "UInt32", size: .auto, isStatic: false)],
				[Property(name: "index2", type: "UInt32", size: .auto, isStatic: false)],
				[Property(name: "tableFileName2Offset", type: "UInt32", size: .auto, isStatic: false)],
				[Property(name: "index3", type: "UInt32", size: .auto, isStatic: false)],
				[Property(name: "tableFileName3Offset", type: "UInt32", size: .auto, isStatic: false)],
				[Property(name: "tableFileName1", type: "String", size: .auto, isStatic: false, offset: .property("tableFileName1Offset"))],
				[Property(name: "tableFileName2", type: "String", size: .auto, isStatic: false, offset: .property("tableFileName2Offset"))],
				[Property(name: "tableFileName3", type: "String", size: .auto, isStatic: false, offset: .property("tableFileName3Offset"))]
			]
		)
	}
}
