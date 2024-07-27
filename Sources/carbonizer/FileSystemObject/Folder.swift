import Foundation

struct Folder {
	var name: String
	var contents: [any FileSystemObject]
}

func createFolder(contentsOf path: URL) throws -> any FileSystemObject {
	let contentPaths = try path.contents()
	
	let contents = try contentPaths
		.filter { !$0.lastPathComponent.starts(with: ".") }
		.map(createFileSystemObject)
		.sorted(by: \.name)
	
	if path.pathExtension == "mar" {
		return MAR(
			name: path.deletingPathExtension().lastPathComponent,
			files: try contents.compactMap(MCM.init)
		)
	}
	
	if contentPaths.contains(where: { $0.lastPathComponent == "header.json" }) {
		return try NDS(
			name: path.lastPathComponent,
			contents: contents
		)
	}
	
	return Folder(
		name: path.lastPathComponent,
		contents: contents
	)
}

extension Folder: FileSystemObject {
	var fileExtension: String { "" }
	
	func savePath(in directory: URL) -> URL {
		let path = directory
			.appending(component: name)
		
		if !path.exists() { return path }
		
		for number in 1... {
			let path = directory
				.appending(component: name + " (\(number))")
			
			if !path.exists() { return path }
		}
		
		fatalError("unreachable")
	}
	
	func write(into directory: URL) throws {
		let path = savePath(in: directory)
		
		try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
		try contents.forEach { try $0.write(into: path) }
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
