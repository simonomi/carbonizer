import BinaryParser
import Foundation

protocol ProprietaryFileData: SendableMetatype {
	static var fileExtension: String { get }
	static var magicBytes: String { get }
	static var packedStatus: PackedStatus { get }
	
	associatedtype Packed: ProprietaryFileData
	func packed(configuration: CarbonizerConfiguration) -> Packed
	
	associatedtype Unpacked: ProprietaryFileData
	func unpacked(configuration: CarbonizerConfiguration) throws -> Unpacked
	
	init(_ data: Datastream, configuration: CarbonizerConfiguration) throws
	func write(to data: Datawriter)
}

extension ProprietaryFileData where Self: BinaryConvertible {
	init(_ data: Datastream, configuration: CarbonizerConfiguration) throws {
		self = try data.read(Self.self)
	}
}

extension ProprietaryFileData where Self: Codable {
	init(_ data: Datastream, configuration: CarbonizerConfiguration) throws {
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
extension Datastream: ProprietaryFileData {
	static let fileExtension = ""
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unknown
	
	func packed(configuration: CarbonizerConfiguration) -> Datastream { self }
	func unpacked(configuration: CarbonizerConfiguration) -> Datastream { self }
	
	convenience init(_ data: Datastream, configuration: CarbonizerConfiguration) {
		self.init(data)
	}
}
