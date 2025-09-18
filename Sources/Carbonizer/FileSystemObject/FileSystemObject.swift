import BinaryParser
import Foundation

protocol FileSystemObject {
	var name: String { get }
	
	func savePath(in folder: URL, with configuration: Carbonizer.Configuration) -> URL
	func write(into folder: URL, with configuration: Carbonizer.Configuration) throws
	
	func packedStatus() -> PackedStatus
	
	associatedtype Packed: FileSystemObject
	func packed(configuration: Carbonizer.Configuration) -> Packed
	
	associatedtype Unpacked: FileSystemObject
	func unpacked(path: [String], configuration: Carbonizer.Configuration) throws -> Unpacked
	
	consuming func postProcessed(with postProcessor: PostProcessor) rethrows -> Self
	
	mutating func setFile(at path: ArraySlice<String>, to content: any FileSystemObject)
}

func fileSystemObject(
	contentsOf path: URL,
	configuration: Carbonizer.Configuration
) throws -> (any FileSystemObject)? {
	do {
		return if try path.isDirectory() {
			try makeFolder(contentsOf: path, configuration: configuration)
		} else {
			try makeFile(contentsOf: path, configuration: configuration)
		}
	} catch {
		throw BinaryParserError.whileReadingFile(path.lastPathComponent, error)
	}
}
