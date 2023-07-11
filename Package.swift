// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "carbonizer",
	platforms: [
		.macOS("13.0"),
		.custom("Windows", versionString: "11")
	],
    targets: [
        .executableTarget(
            name: "carbonizer",
            path: "Sources"
		)
    ]
)
