import Foundation

public enum Action {
	case auto, pack, unpack
	
	fileprivate func resolved(for path: URL) throws -> PackOrUnpack {
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

fileprivate enum PackOrUnpack {
	case pack, unpack
}

extension Carbonizer {
	static func process(
		_ action: Action,
		path filePath: URL,
		into outputFolder: URL,
		configuration: Configuration
	) throws {
#if !IN_CI
		let readStart = Date.now
#endif
		
		// TODO: add priority to logs for things like this
		guard let file = try fileSystemObject(contentsOf: filePath, configuration: configuration) else {
			configuration.log("skipping", filePath.path(percentEncoded: false))
			return
		}
		
		guard file is NDS.Unpacked || file is NDS.Packed else {
			throw InvalidInput()
		}
		
		// TODO: processors
		
#if !IN_CI
		print("\(.red)read", readStart.timeElapsed, "\(.normal)\(.clearToEndOfLine)")
		
		let packUnpackStart = Date.now
#endif
		
		let processedFile: any FileSystemObject
		switch try action.resolved(for: filePath) {
			case .pack:
				processedFile = file.packed(configuration: configuration)
			case .unpack:
				processedFile = try file.unpacked(path: [], configuration: configuration)
		}
		
#if !IN_CI
		print("\(.yellow)pack/unpack", packUnpackStart.timeElapsed, "\(.normal)\(.clearToEndOfLine)")
#endif
		
		// TODO: processors
		
		let savePath = processedFile.savePath(in: outputFolder, with: configuration)
		
		configuration.log("writing to", savePath.path(percentEncoded: false))
		
		// TODO: instead of deleting then writing, write to temporary then swap ?
		// if the swap fails, thats wasteful :/ (but should preserve data)
		if configuration.overwriteOutput && savePath.exists() {
			configuration.log("removing existing file")
			
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
		
		try processedFile.write(into: outputFolder, with: configuration)
		
#if !IN_CI
		print("\(.cyan)write", writeStart.timeElapsed, "\(.normal)\(.clearToEndOfLine)")
#endif
	}
}
