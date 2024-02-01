import BinaryParser
import Foundation

protocol Writeable {
	func write(to path: URL) throws
}

extension BinaryConvertible where Self: Writeable {
	func write(to path: URL) throws {
		let datawriter = Datawriter()
		write(to: datawriter)
		try datawriter.write(to: path)
	}
}

extension Encodable where Self: Writeable {
	func write(to path: URL) throws {
		try JSONEncoder(.prettyPrinted).encode(self).write(to: path)
	}
}

extension Data {
	func write(to path: URL) throws {
		try self.write(to: path, options: [])
	}
}

extension Datastream: Writeable {
	func write(to path: URL) throws {
		try Data(bytes).write(to: path)
	}
}

extension Datawriter: Writeable {
	func write(to path: URL) throws {
		try Data(bytes).write(to: path)
	}
}

extension [any FileSystemObject]: Writeable {
	func write(to inputPath: URL) throws {
		let name = inputPath.lastPathComponent
		let path = inputPath.deletingLastPathComponent()
		
		if count == 1,
		   var firstFile = first as? File,
		   name.hasSuffix(".mar"),
		   let metadata = firstFile.metadata {
			// special case for MAR files with only one child
			firstFile.name = String(name.dropLast(4))
			firstFile.metadata = metadata.swizzle { $0.standalone = true }
			try firstFile.write(into: path, packed: false)
		} else {
			try Folder(name: name, files: self).write(into: path, packed: false)
		}
	}
}
