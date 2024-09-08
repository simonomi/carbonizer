import Foundation
import BinaryParser

struct BinaryFile {
	var name: String
	var fileExtension: String
	var metadata: Metadata?
	var data: Datastream
}

extension BinaryFile: FileSystemObject {
	func savePath(in directory: URL, overwriting: Bool) -> URL {
		let path = directory
			.appending(component: name)
			.appendingPathExtension(fileExtension)
		
		if overwriting || !path.exists() { return path }
		
		for number in 1... {
			let path = directory
				.appending(component: name + " (\(number))")
				.appendingPathExtension(fileExtension)
			
			if !path.exists() { return path }
		}
		
		fatalError("unreachable")
	}
	
	func write(into folder: URL, overwriting: Bool) throws {
		let path = savePath(in: folder, overwriting: overwriting)
		
		do {
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
	
	func packed() -> BinaryFile { self }
	func unpacked() throws -> BinaryFile { self }
}
