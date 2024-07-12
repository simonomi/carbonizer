// swift-tools-version: 5.9
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "carbonizer",
	platforms: [
		.macOS(.v14),
//		.custom("Windows", versionString: "11")
	],
	products: [
		.executable(name: "carbonizer", targets: ["carbonizer"])
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0")
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
			name: "carbonizer",
			dependencies: [
				"BinaryParser",
				.product(name: "ArgumentParser", package: "swift-argument-parser")
			]
		),
		.testTarget(
			name: "BinaryParserTests",
			dependencies: [
				"BinaryParserMacros",
				.product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
			]
		)
    ]
)
