import BinaryParser
import Foundation

#if compiler(<6.2)
protocol SendableMetatype {}
#endif

protocol ProprietaryFileData: SendableMetatype {
	static var fileExtension: String { get }
	static var magicBytes: String { get }
	
	associatedtype Packed: ProprietaryFileData
	func packed(configuration: Configuration) -> Packed
	
	associatedtype Unpacked: ProprietaryFileData
	func unpacked(configuration: Configuration) throws -> Unpacked
	
	init(_ data: inout Datastream, configuration: Configuration) throws
	func write(to data: Datawriter)
}

extension ProprietaryFileData where Self: BinaryConvertible {
	init(_ data: inout Datastream, configuration: Configuration) throws {
		self = try data.read(Self.self)
	}
}

extension ProprietaryFileData where Self: Codable {
	init(_ data: inout Datastream, configuration: Configuration) throws {
		assert(data.offset == 0) // should only read full files as json (?)
		self = try JSONDecoder(allowsJSON5: true).decode(Self.self, from: Data(data.bytes))
	}
	
	func write(to data: Datawriter) {
		// TODO: is it possible to panic here?
		let jsonData = try! JSONEncoder(.prettyPrinted, .sortedKeys).encode(self)
		data.write(jsonData)
	}
}

// used in MARs/MCMs for unknown file type
extension ByteSlice: ProprietaryFileData {
	static let fileExtension = ""
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> Self { self }
	func unpacked(configuration: Configuration) -> Self { self }
	
	init(_ data: inout Datastream, configuration: Configuration) {
		self.init(&data)
	}
}
