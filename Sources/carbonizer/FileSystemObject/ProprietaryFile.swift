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
	
	func savePath(in directory: URL, overwriting: Bool) -> URL {
		BinaryFile(
			name: name + fileExtension,
			metadata: metadata,
			data: Datastream()
		)
		.savePath(in: directory, overwriting: overwriting)
	}
	
	func write(into folder: URL, overwriting: Bool) throws {
		let writer = Datawriter()
		data.write(to: writer)
		
		try BinaryFile(
			name: name + fileExtension,
			metadata: metadata,
			data: writer.intoDatastream()
		)
		.write(into: folder, overwriting: overwriting)
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
