import Foundation

struct Folder: FileSystemObject {
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
		return try MAR(
			name: path.deletingPathExtension().lastPathComponent,
			files: contents
				.compactMap(as: File.self)
				.map(MCM.init)
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

extension Folder {
    func savePath(in directory: URL) -> URL {
        directory.appending(component: name)
    }
    
    func write(into directory: URL) throws {
        let path = savePath(in: directory)
        
        try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        try contents.forEach { try $0.write(into: path) }
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
