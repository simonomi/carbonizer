import XCTest
import SwiftSyntax

@testable import BinaryParserMacros

func assert(properties: [Property], expandTo expectedSource: String, in structName: String = "Offset") {
	var actualSource = properties
		.map { $0.makeInitialization() }
		.joined(separator: "\n")
	
	// to make test failures easier to read
	let expectedSource = "\n" + expectedSource + "\n"
	actualSource = "\n" + actualSource + "\n"
	
	XCTAssertEqual(expectedSource, actualSource)
}

func assert(property: Property, expandsTo expectedSource: String, in structName: String = "Offset") {
	var actualSource = property.makeInitialization()
	
	// to make test failures easier to read
	let expectedSource = "\n" + expectedSource + "\n"
	actualSource = "\n" + actualSource + "\n"
	
	XCTAssertEqual(expectedSource, actualSource)
}

final class MakeInitializationTests: XCTestCase {
	func testStrings() {
		assert(
			properties: [
				Property(name: "string1", type: "String", size: .auto, isStatic: false),
				Property(name: "string2", type: "String", size: .auto, isStatic: false, expected: #""expected""#)
			],
			expandTo: #"""
				string1 = try data.read(String.self)
				string2 = try data.read(String.self)
				guard string2 == "expected" else {
					throw BinaryParserAssertionError(expected: "expected", actual: string2)
				}
				"""#
		)
	}
	
	func testIfCondition() {
		assert(
			property: Property(name: "string", type: "String", size: .auto, isStatic: false, ifCondition: "test == 1"),
			expandsTo: #"""
				if test == 1 {
					string = try data.read(String.self)
				}
				"""#
		)
	}
	
	func testEndOffset() {
		assert(
			properties: [
				Property(name: "data1", type: "[Data]", size: .offsets(.givenByPath("offsets")), isStatic: false, endOffset: "endOffset"),
				Property(name: "data2", type: "[Data]", size: .offsets(.givenByPath("offsets")), isStatic: false, endOffset: 7)
			],
			expandTo: #"""
				data1 = try data.read([Data].self, offsets: offsets, endOffset: endOffset, relativeTo: base)
				data2 = try data.read([Data].self, offsets: offsets, endOffset: 7, relativeTo: base)
				"""#
		)
	}
	
	func testPadding() {
		assert(
			properties: [
				Property(name: "padded", type: "UInt32", size: .auto, isStatic: false, padding: .value(2))
			],
			expandTo: #"""
				data.jump(bytes: 2)
				padded = try data.read(UInt32.self)
				"""#
		)
	}
	
	func testInts() {
		assert(
			properties: [
				Property(name: "uint8", type: "UInt8", size: .auto, isStatic: false),
				Property(name: "uint16", type: "UInt16", size: .auto, isStatic: false),
				Property(name: "uint32", type: "UInt32", size: .auto, isStatic: false),
				Property(name: "uint64", type: "UInt64", size: .auto, isStatic: false),
				Property(name: "int8", type: "Int8", size: .auto, isStatic: false),
				Property(name: "int16", type: "Int16", size: .auto, isStatic: false),
				Property(name: "int32", type: "Int32", size: .auto, isStatic: false),
				Property(name: "int64", type: "Int64", size: .auto, isStatic: false)
			],
			expandTo: #"""
				uint8 = try data.read(UInt8.self)
				uint16 = try data.read(UInt16.self)
				uint32 = try data.read(UInt32.self)
				uint64 = try data.read(UInt64.self)
				int8 = try data.read(Int8.self)
				int16 = try data.read(Int16.self)
				int32 = try data.read(Int32.self)
				int64 = try data.read(Int64.self)
				"""#
		)
	}
}
