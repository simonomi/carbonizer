import Foundation
import BinaryParser

struct BinaryFile {
	var name: String
	var fileExtension: String
	var metadata: Metadata?
	var data: Datastream
}

extension BinaryFile: FileSystemObject {
	func savePath(in directory: URL) -> URL {
		let path = directory
			.appending(component: name)
			.appendingPathExtension(fileExtension)
		
		if !path.exists() { return path }
		
		for number in 1... {
			let path = directory
				.appending(component: name + " (\(number))")
				.appendingPathExtension(fileExtension)
			
			if !path.exists() { return path }
		}
		
		fatalError("unreachable")
	}
	
	func write(into directory: URL) throws {
		let filePath = savePath(in: directory)
		
		do {
			try Data(data.bytes).write(to: filePath)
		} catch {
			throw BinaryParserError.whileWriting(Self.self, error)
		}
		
		if let metadataDate = metadata?.asDate {
			do {
				try filePath.setCreationDate(to: metadataDate)
			} catch {
				throw BinaryParserError.whileWriting(Metadata.self, error)
			}
		}
	}
	
	func packedStatus() -> PackedStatus { .unknown }
	
	func packed() -> BinaryFile { self }
	func unpacked() throws -> BinaryFile { self }
}
