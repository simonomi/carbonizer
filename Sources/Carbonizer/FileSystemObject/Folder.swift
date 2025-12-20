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
) async throws -> (any FileSystemObject)? {
	let metadata = try Metadata(forItemAt: path, configuration: configuration)
	if metadata?.skipFile == true { return nil }
	
	configuration.log(.transient, "reading", path.path(percentEncoded: false))
	
	let contentPaths = try path.contents()
	
	let contents = try await withThrowingTaskGroup { group in
		for itemPath in contentPaths where !itemPath.lastPathComponent.starts(with: ".") {
			group.addTask {
				try await fileSystemObject(contentsOf: itemPath, configuration: configuration)
			}
		}
		
		var contents: [any FileSystemObject] = []
		for try await item in group {
			guard let item else { continue }
			
			contents.append(item)
		}
		
		return contents.sorted(by: \.name)
	}
	
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
	) async throws {
		configuration.log(.transient, "writing", path.path(percentEncoded: false))
		try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
		
		try metadata?.write(on: path, configuration: configuration)
		
		try await withThrowingTaskGroup { group in
			for item in contents {
				group.addTask {
					try await item.write(into: path, with: configuration)
				}
			}
			
			try await group.waitForAll()
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
