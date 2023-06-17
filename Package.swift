// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "carbonizer",
	platforms: [
		.macOS(.v13)
	],
    targets: [
        .executableTarget(
            name: "carbonizer",
            path: "Sources"
		)
    ]
)
