// swift-tools-version: 6.1
import PackageDescription
import CompilerPluginSupport

let package = Package(
	name: "carbonizer",
 	platforms: [
 		.macOS(.v15),
		.custom("Windows", versionString: "11")
 	],
	products: [
		.executable(name: "carbonizer", targets: ["Carbonizer"])
	],
	dependencies: [
		.package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.1"),
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
//		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.6.0"),
//		.package(url: "https://github.com/apple/SwiftUsd", from: "5.0.2"),
	],
	targets: [
		.macro(
			name: "BinaryParserMacros",
			dependencies: [
				.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax")
			]
		),
		.target(name: "BinaryParser", dependencies: ["BinaryParserMacros"]),
		.executableTarget(
			name: "Carbonizer",
			dependencies: [
				"BinaryParser",
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
//				.product(name: "OpenUSD", package: "SwiftUsd"),
			],
//			swiftSettings: [
//				.interoperabilityMode(.Cxx)
//			]
		),
		// enabling this target somehow results in CarbonizerTests not being able to import Carbonizer
//		.testTarget(
//			name: "BinaryParserTests",
//			dependencies: [
//				"BinaryParserMacros",
//				.product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
//			]
//		),
		.testTarget(
			name: "CarbonizerTests",
			dependencies: ["Carbonizer"],
//			swiftSettings: [
//				.interoperabilityMode(.Cxx)
//			]
		)
	],
	cxxLanguageStandard: .gnucxx17
)
