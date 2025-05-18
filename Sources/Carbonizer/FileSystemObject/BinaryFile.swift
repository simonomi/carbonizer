import Foundation
import BinaryParser

struct BinaryFile {
	var name: String
	var metadata: Metadata?
	var data: Datastream
}

extension BinaryFile: FileSystemObject {
	func savePath(in directory: URL, overwriting: Bool) -> URL {
		let path = directory.appending(component: name)
		
		if overwriting || !path.exists() { return path }
		
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
		overwriting: Bool,
		with configuration: CarbonizerConfiguration
	) throws {
		let path = savePath(in: folder, overwriting: overwriting)
		
		do {
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
	
	func packed(configuration: CarbonizerConfiguration) -> BinaryFile { self }
	func unpacked(path: [String] = [], configuration: CarbonizerConfiguration) throws -> BinaryFile { self }
}
