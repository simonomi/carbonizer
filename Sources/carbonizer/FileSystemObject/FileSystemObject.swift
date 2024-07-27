import BinaryParser
import Foundation

protocol FileSystemObject {
	var name: String { get }
	var fileExtension: String { get }
	var fullName: String { get }
	
	func savePath(in directory: URL) -> URL
	func write(into directory: URL) throws
	
	func packedStatus() -> PackedStatus
	
	associatedtype Packed: FileSystemObject
	func packed() -> Packed
	associatedtype Unpacked: FileSystemObject
	func unpacked() throws -> Unpacked
	
//	consuming func postProcessed(with postProcessor: PostProcessor) rethrows -> Self
}

extension FileSystemObject {
	var fullName: String {
		combineFileName(name, withExtension: fileExtension)
	}
}

func createFileSystemObject(contentsOf path: URL) throws -> any FileSystemObject {
	do {
		return switch try path.type() {
			case .folder:
				try createFolder(contentsOf: path)
			case .file:
				try createFile(contentsOf: path)
			case .other(let otherType):
				throw FileReadError.invalidFileType(path, otherType)
		}
	} catch {
		throw BinaryParserError.whileReadingFile(path.path(percentEncoded: false), "", "", error)
	}
}

enum FileReadError: Error {
	case invalidFileType(URL, FileAttributeType?)
}
