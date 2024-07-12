import BinaryParser
import Foundation

extension Data: FileData, Writeable {
	static var packedFileExtension = ""
	static var unpackedFileExtension = "json"
	
	init(packed: Datastream) {
		self = Data(packed.bytes)
	}
}

extension Datastream: InitFrom {
	typealias InitsFrom = Data
}
