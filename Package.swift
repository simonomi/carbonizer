// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "carbonizer",
    targets: [
        .executableTarget(
            name: "carbonizer",
            path: "Sources"
		)
    ]
)
