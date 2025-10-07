import Foundation

public enum Action {
	case auto, pack, unpack
	
	func resolved(for path: URL) throws -> PackOrUnpack {
		switch self {
			case .auto:
				if try path.isDirectory() {
					.pack
				} else {
					.unpack
				}
			case .pack: .pack
			case .unpack: .unpack
		}
	}
}

extension Carbonizer {
	static func run(
		_ action: Action,
		path filePath: URL,
		into outputFolder: URL,
		configuration: Configuration
	) throws {
		let action = try action.resolved(for: filePath)
		
#if !IN_CI
		let readStart = Date.now
#endif
		
		if !configuration.fileTypes.contains("MAR") {
			configuration.log(.warning, "the \(.cyan)MAR\(.normal) file type was not enabled, no files inside the ROM will be processed")
		}
		
		configuration.log(.checkpoint, "reading", filePath.path(percentEncoded: false))
		
		guard var file = try fileSystemObject(contentsOf: filePath, configuration: configuration),
		      (file is NDS.Unpacked || file is NDS.Packed)
		else {
			throw InvalidInput()
		}
		
#if !IN_CI
		print("\(.red)read", readStart.timeElapsed, "\(.normal)\(.clearToEndOfLine)")
		let firstProcessorsStart = Date.now
#endif
		
		try runProcessors(on: &file, when: action, configuration: configuration)
		
#if !IN_CI
		print("\(.yellow)process", firstProcessorsStart.timeElapsed, "\(.normal)\(.clearToEndOfLine)")
		let packUnpackStart = Date.now
#endif
		
		switch action {
			case .pack:
				file = file.packed(configuration: configuration)
			case .unpack:
				file = try file.unpacked(path: [], configuration: configuration)
		}
		
#if !IN_CI
		print("\(.yellow)pack/unpack", packUnpackStart.timeElapsed, "\(.normal)\(.clearToEndOfLine)")
		let secondProcessorsStart = Date.now
#endif
		
		try runProcessors(on: &file, when: action, configuration: configuration)
		
#if !IN_CI
		print("\(.yellow)process", secondProcessorsStart.timeElapsed, "\(.normal)\(.clearToEndOfLine)")
#endif
		
		let savePath = file.savePath(in: outputFolder, with: configuration)
		
		configuration.log(.checkpoint, "writing to", savePath.path(percentEncoded: false))
		
		// TODO: instead of deleting then writing, write to temporary then swap ?
		// if the swap fails, thats wasteful :/ (but should preserve data)
		if configuration.overwriteOutput && savePath.exists() {
			configuration.log(.checkpoint, "removing existing file")
			
#if !IN_CI
			let removeStart = Date.now
#endif
			
			try FileManager.default.removeItem(at: savePath)
			
#if !IN_CI
			print("\(.red)remove", removeStart.timeElapsed, "\(.normal)\(.clearToEndOfLine)")
#endif
		}
		
#if !IN_CI
		let writeStart = Date.now
#endif
		
		try file.write(into: outputFolder, with: configuration)
		
#if !IN_CI
		print("\(.cyan)write", writeStart.timeElapsed, "\(.normal)\(.clearToEndOfLine)")
#endif
	}
}
