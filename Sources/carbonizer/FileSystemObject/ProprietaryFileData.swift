import BinaryParser
import Foundation

protocol ProprietaryFileData: BinaryConvertible {
	static var fileExtension: String { get }
	static var magicBytes: String { get }
	
	static var packedStatus: PackedStatus { get }
	
	associatedtype Packed: ProprietaryFileData where Packed.Unpacked == Self
	init(_ packed: Packed)
	
	associatedtype Unpacked: ProprietaryFileData where Unpacked.Packed == Self
	init(_ unpacked: Unpacked)
}

extension ProprietaryFileData {
	fileprivate static func selfAndPacked() -> [any ProprietaryFileData.Type] {
		[Self.self, Packed.self]
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
		"CHR": CHR.self,
		"DCL": DCL.self,
		"DEX": DEX.self,
		"DMG": DMG.self,
		"DMS": DMS.self,
		"DTX": DTX.self,
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
		return try data.read(fileType) as any ProprietaryFileData
	}
	
	let marker = data.placeMarker()
	let magicBytes = try? data.read(String.self, exactLength: 3) // note: in ffc, donate_mask_defs has DMSK
	data.jump(to: marker)
	
	if let fileType = fileTypes.first(where: { $0.magicBytes == magicBytes }) {
		return try data.read(fileType) as any ProprietaryFileData
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
	func packed() -> Packed { Packed(self) }
	func unpacked() -> Unpacked { Unpacked(self) }
}

extension Datastream: ProprietaryFileData {
	typealias Packed = Datastream
	typealias Unpacked = Datastream
	static let fileExtension = ""
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unknown
}
