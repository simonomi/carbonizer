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
		.executable(name: "carbonizer", targets: ["CarbonizerCLI"]),
		.library(name: "Carbonizer", targets: ["Carbonizer"])
	],
	dependencies: [
		.package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.1"),
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
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
		.target(
			name: "Carbonizer",
			dependencies: [
				"BinaryParser",
				"ANSICodes",
//				.product(name: "OpenUSD", package: "SwiftUsd"),
			],
//			swiftSettings: [
//				.interoperabilityMode(.Cxx)
//			]
		),
		.target(name: "ANSICodes"),
		.executableTarget(
			name: "CarbonizerCLI",
			dependencies: [
				"Carbonizer",
				"ANSICodes",
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			]
		),
		.testTarget(
			name: "CarbonizerTests",
			dependencies: ["Carbonizer"],
//			swiftSettings: [
//				.interoperabilityMode(.Cxx)
//			]
		),
		.testTarget(name: "CarbonizerCLITests", dependencies: ["CarbonizerCLI"])
	],
	cxxLanguageStandard: .gnucxx17
)
