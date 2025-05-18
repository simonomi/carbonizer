import BinaryParser
import Foundation

protocol FileSystemObject {
	var name: String { get }
	
	func savePath(in folder: URL, overwriting: Bool) -> URL
	func write(
		into folder: URL,
		overwriting: Bool,
		with configuration: CarbonizerConfiguration
	) throws
	
	func packedStatus() -> PackedStatus
	
	associatedtype Packed: FileSystemObject
	func packed(configuration: CarbonizerConfiguration) -> Packed
	associatedtype Unpacked: FileSystemObject
	func unpacked(path: [String], configuration: CarbonizerConfiguration) throws -> Unpacked
	
	consuming func postProcessed(with postProcessor: PostProcessor) rethrows -> Self
	
	mutating func setFile(at path: ArraySlice<String>, to content: any FileSystemObject)
}

func fileSystemObject(
	contentsOf path: URL,
	configuration: CarbonizerConfiguration
) throws -> any FileSystemObject {
	do {
		return switch try path.type() {
			case .folder:
				try createFolder(contentsOf: path, configuration: configuration)
			case .file:
				try createFile(contentsOf: path, configuration: configuration)
			case .other(let otherType):
				throw FileReadError.invalidFileType(path, otherType)
		}
	} catch {
		throw BinaryParserError.whileReadingFile(path.lastPathComponent, error)
	}
}

enum FileReadError: Error {
	case invalidFileType(URL, FileAttributeType?)
}
