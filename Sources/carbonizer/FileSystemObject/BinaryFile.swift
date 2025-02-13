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
	
	func write(into folder: URL, overwriting: Bool) throws {
		let path = savePath(in: folder, overwriting: overwriting)
		
		do {
			if !folder.exists() {
				try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
			}
			
			try Data(data.bytes).write(to: path)
		} catch {
			throw BinaryParserError.whileWriting(Self.self, error)
		}
		
		if let metadataDate = metadata?.asDate {
			do {
				try path.setCreationDate(to: metadataDate)
			} catch {
				throw BinaryParserError.whileWriting(Metadata.self, error)
			}
		}
	}
	
	func packedStatus() -> PackedStatus { .unknown }
	
	func packed(configuration: CarbonizerConfiguration) -> BinaryFile { self }
	func unpacked(configuration: CarbonizerConfiguration) throws -> BinaryFile { self }
}
