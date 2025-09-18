import Foundation

public extension Carbonizer {
	static func pack(
		_ filePath: URL,
		into outputFolder: URL,
		configuration: Configuration
	) throws {
		todo()
		
		guard let file = try fileSystemObject(contentsOf: filePath, configuration: configuration) else {
			configuration.log("skipping", filePath.path(percentEncoded: false))
			return
		}
		
		guard file is NDS.Unpacked else {
			if file is NDS.Packed {
				todo("should this be a noop... or...?")
			} else {
				throw InvalidInput()
			}
		}
		
		// dialogue saver
		
		// pack file
		
		// write packed file
		// if overwrite and exists, delete existing
		// TODO: use fancy swap-without-losing-data command?
	}
}
