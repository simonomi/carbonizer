import ANSICodes
import Foundation

// TODO: list
// - add a `carbonizer version.json` file or smthn to contain the version number
//   - if trying to pack from too old a version (semver or smthn), give an error
//   - also the list of file types, so if some file types were extracted they need to be repacked
// - make reading (and writing?) use way fewer filesystem calls
//   - enumerator

public enum Carbonizer {
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
