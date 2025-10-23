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
	
	func savePath(in directory: URL, with configuration: Configuration) -> URL {
		BinaryFile(
			name: name + fileExtension,
			metadata: metadata,
			data: Datastream()
		)
		.savePath(in: directory, with: configuration)
	}
	
	func write(
		into folder: URL,
		with configuration: Configuration
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
	
	func packed(configuration: Configuration) -> Self {
		ProprietaryFile(
			name: name,
			metadata: metadata,
			data: data.packed(configuration: configuration) as any ProprietaryFileData
		)
	}
	
	func unpacked(path: [String] = [], configuration: Configuration) throws -> Self {
		ProprietaryFile(
			name: name,
			metadata: metadata,
			data: try data.unpacked(configuration: configuration) as any ProprietaryFileData
		)
	}
}
