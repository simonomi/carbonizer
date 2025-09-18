import Foundation

public extension Carbonizer {
	static func monitor(
		_ filePath: URL,
		into outputFolder: URL,
		configuration: Configuration
	) async throws {
#if os(macOS)
		guard configuration.overwriteOutput else {
			print("\(.red)overwriteOutput should be on\(.normal)")
			fatalError()
		}
		
		guard var fileData = try fileSystemObject(contentsOf: filePath, configuration: configuration) else {
			// TODO: throw
			todo()
//			print("\(.red, .bold)Error:\(.normal) \(.bold)could not make FileSystemObject from '\(filePath.path(percentEncoded: false))'\(.normal)")
//			if configuration.keepWindowOpen.isTrueOnError {
//				waitForInput()
//			}
//			return
		}
		
		let outputFolder = outputFolder
		
		try monitorFiles(in: filePath) {
			let components = $0
				.deletingPathExtension()
				.deletingPathExtension()
				.pathComponents
				.dropFirst(5)
			
			guard let newFile = try makeFile(contentsOf: $0, configuration: configuration) else { return }
			
			fileData.setFile(at: components, to: newFile)
			
			let packedData = fileData.packed(configuration: configuration)
			let outputPath = packedData.savePath(in: outputFolder, with: configuration)
			try packedData.write(into: outputFolder, with: configuration)
			
			try shell("open \"\(outputPath.path(percentEncoded: false))\"")
		}
		
		print("ready!")
#else
		// TODO: throw
		var standardError = FileHandle.standardError
		print("\(.red, .bold)Error:\(.normal) \(.bold)Hot reloading is only available on macOS\(.normal)", terminator: "\n\n", to: &standardError)
		if configuration.keepWindowOpen.isTrueOnError {
			waitForInput()
		}
		return
#endif
	}
}
