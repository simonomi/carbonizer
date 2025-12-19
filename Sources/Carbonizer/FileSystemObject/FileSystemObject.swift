import BinaryParser
import Foundation

protocol FileSystemObject {
	var name: String { get }
	
	func savePath(in folder: URL, with configuration: Configuration) -> URL
	func write(at path: URL, with configuration: Configuration) throws
	
	associatedtype Packed: FileSystemObject
	func packed(configuration: Configuration) throws -> Packed
	
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

extension FileSystemObject {
	func write(into path: URL, with configuration: Configuration) throws {
		try write(
			at: savePath(in: path, with: configuration),
			with: configuration
		)
	}
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
