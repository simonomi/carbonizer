import Foundation

#if os(macOS)
extension Carbonizer {
	func monitor() async throws {
		let folderPath = URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters/")
		
		var fileData = try createFileSystemObject(contentsOf: folderPath)
		
		let outputPath = URL(filePath: "/Users/simonomi/ff1/output")
		let outputFile = URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters.nds")
		
		let monitor = try monitorFiles(in: folderPath) {
			if outputFile.exists() {
				try FileManager.default.removeItem(at: outputFile)
			}
			
			let components = $0
				.deletingPathExtension()
				.deletingPathExtension()
				.pathComponents
				.dropFirst(6)
			
			let newFile = try createFile(contentsOf: $0)
			
			fileData.setFile(at: components, to: newFile)
			
			try fileData.packed().write(into: outputPath)
			
			try shell("open \"\(outputFile.path(percentEncoded: false))\"")
		}
		
		print("ready!")
		try await Task.sleep(for: .seconds(1_000_000))
		
		monitor.cancel()
	}
}
#endif
