import BinaryParser
import Foundation

#if compiler(<6.2)
protocol SendableMetatype {}
#endif

protocol ProprietaryFileData: Sendable, SendableMetatype {
	static var fileExtension: String { get }
	static var magicBytes: String { get }
	
	associatedtype Packed: ProprietaryFileData
	func packed(configuration: Configuration) -> Packed
	
	associatedtype Unpacked: ProprietaryFileData
	func unpacked(configuration: Configuration) throws -> Unpacked
	
	init(_ data: inout Datastream, configuration: Configuration) throws
	func write(to data: Datawriter, configuration: Configuration)
}

extension ProprietaryFileData where Self: BinaryConvertible {
	init(_ data: inout Datastream, configuration: Configuration) throws {
		self = try data.read(Self.self)
	}
	
	func write(to data: Datawriter, configuration: Configuration) {
		write(to: data)
	}
}

extension ProprietaryFileData where Self: Codable {
	init(_ data: inout Datastream, configuration: Configuration) throws {
		assert(data.offset == 0) // should only read full files as json (?)
		self = try JSONDecoder(allowsJSON5: true).decode(Self.self, from: Data(data.bytes))
	}
	
	func write(to data: Datawriter, configuration: Configuration) {
		// TODO: is it possible to panic here?
		var jsonData = try! JSONEncoder(.prettyPrinted, .sortedKeys).encode(self)
		
		if jsonData.last != Character("\n").asciiValue! {
			jsonData.append(Character("\n").asciiValue!)
		}
		
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
	
	func write(to data: Datawriter, configuration: Configuration) {
		write(to: data)
	}
}
