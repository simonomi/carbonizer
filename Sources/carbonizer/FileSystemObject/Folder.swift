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
		.map { try fileSystemObject(contentsOf: $0, configuration: configuration) }
		.sorted(by: \.name)
	
	if configuration.fileTypes.contains(String(describing: MAR.self)),
	   path.lastPathComponent.hasSuffix(MAR.fileExtension) 
	{
		return MAR(
			name: String(path.lastPathComponent.dropLast(MAR.fileExtension.count)),
			files: try contents.compactMap(MCM.init),
			configuration: configuration
		)
	}
	
	if contentPaths.contains(where: { $0.lastPathComponent == "header.json" }) {
		return try NDS(
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
	
	func write(into folder: URL, overwriting: Bool) throws {
		let path = savePath(in: folder, overwriting: overwriting)
		try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
		try contents.forEach { try $0.write(into: path, overwriting: overwriting) }
	}
	
	func packedStatus() -> PackedStatus {
		contents
			.map { $0.packedStatus() }
			.reduce(.unknown) { $0.combined(with: $1) }
	}
	
	func packed() -> Self {
		Folder(
			name: name,
			contents: contents.map { $0.packed() }
		)
	}
	
	func unpacked() throws -> Self {
		Folder(
			name: name,
			contents: try contents.map { try $0.unpacked() }
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
