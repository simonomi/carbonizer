import ANSICodes
import Foundation

// TODO: list
// - make reading (and writing?) use way fewer filesystem calls
//   - enumerator
// - error if packing with fewer filetypes

public enum Carbonizer {
	// if run manually, CI will check for the string "main", so here you go :)
	static let version = "v2.18"
	
	public static func auto(
		_ filePath: URL,
		into outputFolder: URL,
		configuration: Configuration
	) throws {
		try run(.auto, path: filePath, into: outputFolder, configuration: configuration)
	}
	
	public static func pack(
		_ filePath: URL,
		into outputFolder: URL,
		configuration: Configuration
	) throws {
		try run(.pack, path: filePath, into: outputFolder, configuration: configuration)
	}
	
	public static func unpack(
		_ filePath: URL,
		into outputFolder: URL,
		configuration: Configuration
	) throws {
		try run(.unpack, path: filePath, into: outputFolder, configuration: configuration)
	}
}
