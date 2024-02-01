import BinaryParser
import Foundation

extension Datastream: FileData {
	static var packedFileExtension = ""
	static var unpackedFileExtension = "bin"
	
	convenience init(packed: Datastream) {
		self.init(packed)
	}
	
	convenience init(unpacked: Datastream) {
		self.init(unpacked)
	}
	
	func toPacked() -> Datastream { self }
	
	func toUnpacked() -> Datastream { self }
}
