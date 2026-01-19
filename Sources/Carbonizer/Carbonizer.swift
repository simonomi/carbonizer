import Foundation

public enum Carbonizer {
	// if run manually, CI will check for the string "main", so here you go :)
	public static let version = "v2.21"
	
	public static func auto(
		_ filePath: URL,
		into outputFolder: URL,
		configuration: Configuration
	) async throws {
		try await run(.auto, path: filePath, into: outputFolder, configuration: configuration)
	}
	
	public static func pack(
		_ filePath: URL,
		into outputFolder: URL,
		configuration: Configuration
	) async throws {
		try await run(.pack, path: filePath, into: outputFolder, configuration: configuration)
	}
	
	public static func unpack(
		_ filePath: URL,
		into outputFolder: URL,
		configuration: Configuration
	) async throws {
		try await run(.unpack, path: filePath, into: outputFolder, configuration: configuration)
	}
}
