import BinaryParser
import Foundation

protocol ProprietaryFileData {
	static var fileExtension: String { get }
	static var magicBytes: String { get }
	
	static var packedStatus: PackedStatus { get }
	
	associatedtype Packed: ProprietaryFileData where Packed.Unpacked == Self
	init(_ packed: Packed, configuration: CarbonizerConfiguration)
	
	associatedtype Unpacked: ProprietaryFileData where Unpacked.Packed == Self
	init(_ unpacked: Unpacked, configuration: CarbonizerConfiguration)
	
	init(_ data: Datastream, configuration: CarbonizerConfiguration) throws
	func write(to data: Datawriter)
}

extension ProprietaryFileData {
	fileprivate static func selfAndPacked() -> [any ProprietaryFileData.Type] {
		[Self.self, Packed.self]
	}
}

extension ProprietaryFileData where Self: BinaryConvertible {
	init(_ data: Datastream, configuration: CarbonizerConfiguration) throws {
		self = try data.read(Self.self)
	}
}

extension String {
	func hasExtension(of fileType: any ProprietaryFileData.Type) -> Bool {
		fileType.fileExtension.isNotEmpty && self.hasSuffix(fileType.fileExtension)
	}
}

func createFileData(
	name: String,
	data: Datastream,
	configuration: CarbonizerConfiguration
) throws -> (any ProprietaryFileData)? {
	let allFileTypes: [String: any ProprietaryFileData.Type] = [
		"BBG": BBG.self,
		"CHR": CHR.self,
		"DBS": DBS.self,
		"DCL": DCL.self,
		"DEP": DEP.self,
		"DEX": DEX.self,
		"DMG": DMG.self,
		"DMS": DMS.self,
		"DTX": DTX.self,
		"ECS": ECS.self,
		"GRD": GRD.self,
		"KIL": KIL.self,
		"MAP": MAP.self,
		"MFS": MFS.self,
		"MM3": MM3.self,
		"MMS": MMS.self,
		"MPM": MPM.self,
		"RLS": RLS.self,
		"3CL": TCL.self
	]
	
	let fileTypes: [any ProprietaryFileData.Type] = allFileTypes
		.filter { (fileTypeName, _) in
			configuration.fileTypes.contains(fileTypeName)
		}
		.flatMap { (_, fileType) in
			fileType.selfAndPacked()
		}
	
	if let fileType = fileTypes.first(where: name.hasExtension) {
		return try fileType.init(data, configuration: configuration) as any ProprietaryFileData
	}
	
	let marker = data.placeMarker()
	let magicBytes = try? data.read(String.self, exactLength: 3) // note: in ffc, donate_mask_defs has DMSK
	data.jump(to: marker)
	
	if let fileType = fileTypes.first(where: { $0.magicBytes == magicBytes }) {
		return try fileType.init(data, configuration: configuration) as any ProprietaryFileData
	}
	
	return nil
}

extension ProprietaryFileData where Self: Codable {
	init(_ data: Datastream) throws {
		assert(data.offset == 0) // should only read full files as json (?)
		self = try JSONDecoder(allowsJSON5: true).decode(Self.self, from: Data(data.bytes))
	}
	
	func write(to data: Datawriter) {
		// TODO: is it possible to panic here?
		let jsonData = try! JSONEncoder(.prettyPrinted, .sortedKeys).encode(self)
		data.write(jsonData)
	}
}

extension ProprietaryFileData {
	func packed(configuration: CarbonizerConfiguration) -> Packed {
		Packed(self, configuration: configuration)
	}
	func unpacked(configuration: CarbonizerConfiguration) -> Unpacked {
		Unpacked(self, configuration: configuration)
	}
}

extension Datastream: ProprietaryFileData {
	typealias Packed = Datastream
	typealias Unpacked = Datastream
	static let fileExtension = ""
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unknown
	
	convenience init(_ packed: Datastream, configuration: CarbonizerConfiguration) {
		self.init(packed)
	}
}
