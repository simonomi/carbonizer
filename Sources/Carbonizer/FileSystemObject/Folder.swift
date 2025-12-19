import Foundation
import BinaryParser

struct Folder {
	var name: String
	var metadata: Metadata?
	var contents: [any FileSystemObject]
}

func makeFolder(
	contentsOf path: URL,
	configuration: Configuration
) throws -> (any FileSystemObject)? {
	let metadata = try Metadata(forItemAt: path, configuration: configuration)
	if metadata?.skipFile == true { return nil }
	
	configuration.log(.transient, "reading", path.path(percentEncoded: false))
	
	let contentPaths = try path.contents()
	
	let contents = try contentPaths
		.filter { !$0.lastPathComponent.starts(with: ".") }
		.compactMap { try fileSystemObject(contentsOf: $0, configuration: configuration) }
		.sorted(by: \.name)
	
	if configuration.fileTypes.contains(MAR.Packed.Binary.magicBytes),
	   path.lastPathComponent.hasSuffix(MAR.Unpacked.fileExtension)
	{
		return MAR.Unpacked(
			name: String(path.lastPathComponent.dropLast(MAR.Unpacked.fileExtension.count)),
			files: try contents.compactMap(MCM.Unpacked.init)
		)
	}
	
	if contentPaths.contains(where: { $0.lastPathComponent == "header.json" }) {
		return try NDS.Unpacked(
			name: path.lastPathComponent,
			contents: contents,
			configuration: configuration
		)
	}
	
	return Folder(
		name: path.lastPathComponent,
		contents: contents
	)
}

extension Folder: FileSystemObject {
	var fileExtension: String { "" }
	
	func savePath(in directory: URL, with configuration: Configuration) -> URL {
		let path = directory
			.appending(component: name)
		
		if configuration.overwriteOutput || !path.exists() { return path }
		
		for number in 1... {
			let path = directory
				.appending(component: name + " (\(number))")
			
			if !path.exists() { return path }
		}
		
		fatalError("unreachable")
	}
	
	func write(
		at path: URL,
		with configuration: Configuration
	) throws {
		configuration.log(.transient, "writing", path.path(percentEncoded: false))
		try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
		
		if let metadata {
			do {
				if configuration.externalMetadata {
					let metadataPath = path
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
		
		try contents.forEach {
			try $0.write(into: path, with: configuration)
		}
	}
	
	func packed(configuration: Configuration) throws -> Self {
		Folder(
			name: name,
			metadata: metadata,
			contents: try contents.map { try $0.packed(configuration: configuration) }
		)
	}
	
	func unpacked(path: [String], configuration: Configuration) throws -> Self {
		Folder(
			name: name,
			metadata: metadata,
			contents: try contents.map {
				if configuration.shouldUnpack(path + [name, $0.name]) {
					try $0.unpacked(
						path: path + [name],
						configuration: configuration
					)
				} else {
					$0
				}
			}
		)
	}
}

// technically this isnt correct, but its mostly probably good enough
extension Folder: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(contents.count)
	}
	
	static func == (lhs: Folder, rhs: Folder) -> Bool {
		lhs.name == rhs.name && lhs.contents.count == rhs.contents.count
	}
}
