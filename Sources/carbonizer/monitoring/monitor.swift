import Foundation

extension Carbonizer {
	func monitor(with configuration: CarbonizerConfiguration) async throws {
#if os(macOS)
		if filePaths.count > 1 {
			print("Note: more than one input file provided, only monitoring the first")
		}
		
		let inputPath = filePaths.first!
		
		var fileData = try fileSystemObject(contentsOf: inputPath, configuration: configuration)
		
		let outputFolder = configuration.outputFolder.map { URL(filePath: $0) } ?? inputPath.deletingLastPathComponent()
		
		let monitor = try monitorFiles(in: inputPath) {
			let components = $0
				.deletingPathExtension()
				.deletingPathExtension()
				.pathComponents
				.dropFirst(6)
			
			let newFile = try createFile(contentsOf: $0, configuration: configuration)
			
			fileData.setFile(at: components, to: newFile)
			
			let packedData = fileData.packed()
			let outputPath = packedData.savePath(in: outputFolder, overwriting: true)
			try packedData.write(into: outputFolder, overwriting: true)
			
			try shell("open \"\(outputPath.path(percentEncoded: false))\"")
		}
		
		print("ready!")
		try await Task.sleep(for: .seconds(1_000_000))
		
		monitor.cancel()
#else
		var standardError = FileHandle.standardError
		print("\(.red, .bold)Error:\(.normal) \(.bold)Hot reloading is only available on macOS\(.normal)", terminator: "\n\n", to: &standardError)
		waitForInput()
		return
#endif
	}
}
