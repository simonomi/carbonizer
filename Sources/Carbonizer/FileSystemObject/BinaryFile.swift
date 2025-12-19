import Foundation
import BinaryParser

struct BinaryFile {
	var name: String
	var metadata: Metadata?
	var data: Data
}

extension BinaryFile: FileSystemObject {
	func savePath(in directory: URL, with configuration: Configuration) -> URL {
		let path = directory.appending(component: name)
		
		if configuration.overwriteOutput || !path.exists() { return path }
		
		let (baseName, fileExtensions) = splitFileName(name)
		
		for number in 1... {
			let path = directory
				.appending(component: "\(baseName) (\(number))")
				.appendingPathExtension(fileExtensions)
			
			if !path.exists() { return path }
		}
		
		fatalError("unreachable")
	}
	
	func write(
		at path: URL,
		with configuration: Configuration
	) throws {
		configuration.log(.transient, "writing", path.path(percentEncoded: false))
		
		do {
			try data.write(to: path)
		} catch {
			throw BinaryParserError.whileWriting(Self.self, error)
		}
		
		try metadata?.write(on: path, configuration: configuration)
	}
	
	func packed(configuration: Configuration) -> BinaryFile { self }
	func unpacked(path: [String] = [], configuration: Configuration) throws -> BinaryFile { self }
}
