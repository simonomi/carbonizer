import Foundation

public extension Carbonizer {
	static func auto(
		_ filePath: URL,
		into outputFolder: URL,
		configuration: Configuration
	) throws {
		if try filePath.isDirectory() {
			try pack(filePath, into: outputFolder, configuration: configuration)
		} else {
			try unpack(filePath, into: outputFolder, configuration: configuration)
		}
	}
}
