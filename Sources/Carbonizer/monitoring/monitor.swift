import Foundation

extension Carbonizer {
	func monitor(with configuration: CarbonizerConfiguration) async throws {
#if os(macOS)
		if filePaths.count > 1 {
			print("Note: more than one input file provided, only monitoring the first")
		}
		
		guard configuration.overwriteOutput else {
			print("\(.red)overwriteOutput should be on\(.normal)")
			fatalError()
		}
		
		let inputPath = filePaths.first!
		
		guard var fileData = try fileSystemObject(contentsOf: inputPath, configuration: configuration) else {
			print("\(.red, .bold)Error:\(.normal) \(.bold)could not make FileSystemObject from '\(inputPath.path(percentEncoded: false))'\(.normal)")
			if configuration.keepWindowOpen.isTrueOnError {
				waitForInput()
			}
			return
		}
		
		let outputFolder = configuration.outputFolder.map { URL(filePath: $0) } ?? inputPath.deletingLastPathComponent()
		
		let monitor = try monitorFiles(in: inputPath) {
			let components = $0
				.deletingPathExtension()
				.deletingPathExtension()
				.pathComponents
				.dropFirst(6)
			
			guard let newFile = try makeFile(contentsOf: $0, configuration: configuration) else { return }
			
			fileData.setFile(at: components, to: newFile)
			
			let packedData = fileData.packed(configuration: configuration)
			let outputPath = packedData.savePath(in: outputFolder, with: configuration)
			try packedData.write(into: outputFolder, with: configuration)
			
			try shell("open \"\(outputPath.path(percentEncoded: false))\"")
		}
		
		print("ready!")
		try await Task.sleep(for: .seconds(1_000_000))
		
		monitor.cancel()
#else
		var standardError = FileHandle.standardError
		print("\(.red, .bold)Error:\(.normal) \(.bold)Hot reloading is only available on macOS\(.normal)", terminator: "\n\n", to: &standardError)
		if configuration.keepWindowOpen.isTrueOnError {
			waitForInput()
		}
		return
#endif
	}
}
