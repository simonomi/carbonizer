import Foundation

struct Folder {
	var name: String
	var contents: [any FileSystemObject]
}

func createFolder(
	contentsOf path: URL,
	configuration: CarbonizerConfiguration
) throws -> any FileSystemObject {
	let contentPaths = try path.contents()
	
	let contents = try contentPaths
		.filter { !$0.lastPathComponent.starts(with: ".") }
		.filter { $0.pathExtension != "metadata" }
		.map { try fileSystemObject(contentsOf: $0, configuration: configuration) }
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
	
	func savePath(in directory: URL, overwriting: Bool) -> URL {
		let path = directory
			.appending(component: name)
		
		if overwriting || !path.exists() { return path }
		
		for number in 1... {
			let path = directory
				.appending(component: name + " (\(number))")
			
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
		try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
		try contents.forEach { try $0.write(into: path, overwriting: overwriting, with: configuration) }
	}
	
	func packedStatus() -> PackedStatus {
		contents
			.map { $0.packedStatus() }
			.reduce(.unknown) { $0.combined(with: $1) }
	}
	
	func packed(configuration: CarbonizerConfiguration) -> Self {
		Folder(
			name: name,
			contents: contents.map { $0.packed(configuration: configuration) }
		)
	}
	
	func unpacked(path: [String], configuration: CarbonizerConfiguration) throws -> Self {
		Folder(
			name: name,
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
