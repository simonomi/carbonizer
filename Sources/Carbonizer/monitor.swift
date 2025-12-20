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
		
		guard var fileData = try await fileSystemObject(
			contentsOf: filePath,
			configuration: configuration
		) else {
			throw InvalidInput()
		}
		
		let monitor = try monitorFiles(in: filePath) {
			let components = $0
				.deletingPathExtension()
				.deletingPathExtension()
				.pathComponents
				.dropFirst(5) // TODO: is this hardcoding `/Users/simonomi/ff1/output/Fossil Fighters`???
			
			guard let newFile = try makeFile(
				contentsOf: $0,
				configuration: configuration
			) else { return }
			
			fileData.setFile(at: components, to: newFile)
			
			let packedData = try fileData.packed(configuration: configuration)
			let outputPath = packedData.savePath(in: outputFolder, with: configuration)
			try await packedData.write(into: outputFolder, with: configuration)
			
			try shell("open \"\(outputPath.path(percentEncoded: false))\"")
		}
		
		configuration.log(.checkpoint, "ready!")
		
		// monitoring ends when the monitor is dropped, so wait for 32 years before dropping it
		try await Task.sleep(for: .seconds(999_999_999))
		monitor.cancel()
#else
		throw OSNotSupported()
#endif
	}
}

struct OSNotSupported: Error, CustomStringConvertible {
	var description: String {
		"\(.bold)Hot reloading is only available on macOS\(.normal)"
	}
}
