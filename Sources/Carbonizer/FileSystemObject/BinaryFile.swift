import Foundation
import BinaryParser

struct BinaryFile {
	var name: String
	var metadata: Metadata?
	var data: Datastream
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
		into folder: URL,
		with configuration: Configuration
	) throws {
		let path = savePath(in: folder, with: configuration)
		configuration.log(.transient, "Writing", path.path(percentEncoded: false))
		
		do {
			// TODO: can this be removed?
			if !folder.exists() {
				try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
			}
			
			try Data(data.bytes).write(to: path)
		} catch {
			throw BinaryParserError.whileWriting(Self.self, error)
		}
		
		if let metadata {
			do {
				if configuration.externalMetadata {
					let metadataPath = path
						.deletingPathExtension()
						.appendingPathExtension("metadata")
					
					try JSONEncoder(.prettyPrinted, .sortedKeys)
						.encode(metadata)
						.write(to: metadataPath)
				} else {
					try path.setCreationDate(to: metadata.asDate)
				}
			} catch {
				throw BinaryParserError.whileWriting(Metadata.self, error)
			}
		}
	}
	
	func packedStatus() -> PackedStatus { .unknown }
	
	func packed(configuration: Configuration) -> BinaryFile { self }
	func unpacked(path: [String] = [], configuration: Configuration) throws -> BinaryFile { self }
}
