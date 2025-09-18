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
	
	func savePath(in directory: URL, with configuration: Carbonizer.Configuration) -> URL {
		BinaryFile(
			name: name + fileExtension,
			metadata: metadata,
			data: Datastream()
		)
		.savePath(in: directory, with: configuration)
	}
	
	func write(
		into folder: URL,
		with configuration: Carbonizer.Configuration
	) throws {
		let writer = Datawriter()
		data.write(to: writer)
		
		try BinaryFile(
			name: name + fileExtension,
			metadata: metadata,
			data: writer.intoDatastream()
		)
		.write(into: folder, with: configuration)
	}
	
	func packedStatus() -> PackedStatus {
		type(of: data).packedStatus
	}
	
	func packed(configuration: Carbonizer.Configuration) -> Self {
		ProprietaryFile(
			name: name,
			metadata: metadata,
			data: data.packed(configuration: configuration) as any ProprietaryFileData
		)
	}
	
	func unpacked(path: [String] = [], configuration: Carbonizer.Configuration) throws -> Self {
		ProprietaryFile(
			name: name,
			metadata: metadata,
			data: try data.unpacked(configuration: configuration) as any ProprietaryFileData
		)
	}
}
