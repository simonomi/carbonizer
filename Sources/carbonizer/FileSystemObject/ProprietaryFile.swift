import Foundation
import BinaryParser

struct ProprietaryFile {
	var name: String
	var metadata: Metadata?
	var data: any ProprietaryFileData
}

extension ProprietaryFile: FileSystemObject {
	var fileExtension: String {
		type(of: data).fileExtension
	}
	
	func savePath(in directory: URL) -> URL {
		BinaryFile(
			name: name,
			fileExtension: fileExtension,
			metadata: metadata,
			data: Datastream()
		)
		.savePath(in: directory)
	}
	
	func write(into directory: URL) throws {
		let writer = Datawriter()
		data.write(to: writer)
		
		try BinaryFile(
			name: name,
			fileExtension: fileExtension,
			metadata: metadata,
			data: writer.intoDatastream()
		)
		.write(into: directory)
	}
	
	func packedStatus() -> PackedStatus {
		type(of: data).packedStatus
	}
	
	func packed() -> Self {
		ProprietaryFile(
			name: name,
			metadata: metadata,
			data: data.packed() as any ProprietaryFileData
		)
	}
	
	func unpacked() throws -> Self {
		ProprietaryFile(
			name: name,
			metadata: metadata,
			data: data.unpacked()  as any ProprietaryFileData
		)
	}
}
