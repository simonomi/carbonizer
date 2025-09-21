import BinaryParser
import Foundation

protocol FileSystemObject {
	var name: String { get }
	
	func savePath(in folder: URL, with configuration: Configuration) -> URL
	func write(into folder: URL, with configuration: Configuration) throws
	
	func packedStatus() -> PackedStatus
	
	associatedtype Packed: FileSystemObject
	func packed(configuration: Configuration) -> Packed
	
	associatedtype Unpacked: FileSystemObject
	func unpacked(path: [String], configuration: Configuration) throws -> Unpacked
	
	mutating func runProcessor<T>(
		_ processor: ProcessorFunction<T>,
		on glob: Glob,
		in environment: inout Processor.Environment,
		at path: [String],
		configuration: Configuration
	) throws
	
	mutating func setFile(at path: ArraySlice<String>, to content: any FileSystemObject)
}

func fileSystemObject(
	contentsOf path: URL,
	configuration: Configuration
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
