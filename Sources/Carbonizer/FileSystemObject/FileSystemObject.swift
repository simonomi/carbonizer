import BinaryParser
import Foundation

protocol FileSystemObject {
	var name: String { get }
	
	func savePath(in folder: URL, with configuration: CarbonizerConfiguration) -> URL
	func write(into folder: URL, with configuration: CarbonizerConfiguration) throws
	
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
