// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "carbonizer",
	platforms: [
		.macOS(.v13)
	],
//	dependencies: [
//		.package(
//			url: "https://github.com/nixberg/endianbytes-swift.git",
//			from: "0.5.1"
//		)
//	],
    targets: [
        .executableTarget(
            name: "carbonizer",
            path: "Sources"
		)
    ]
)
