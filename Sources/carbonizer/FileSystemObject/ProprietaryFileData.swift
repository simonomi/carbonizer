import BinaryParser
import Foundation

protocol ProprietaryFileData: BinaryConvertible {
	static var fileExtension: String { get }
	
	static var packedStatus: PackedStatus { get }
	
	associatedtype Packed: ProprietaryFileData where Packed.Unpacked == Self
	init(_ packed: Packed)
	
	associatedtype Unpacked: ProprietaryFileData where Unpacked.Packed == Self
	init(_ unpacked: Unpacked)
}

func createFileData(
	_ data: Datastream,
	fileExtension: String
) throws -> (any ProprietaryFileData)? {
	func decode<D: Decodable>(_: D.Type) throws -> D {
		try JSONDecoder().decode(D.self, from: Data(data.bytes))
	}
	
	switch fileExtension {
//		case AIS.fileExtension:
//			return try data.read(AIS.self)
//		case AST.fileExtension:
//			return try data.read(AST.self)
//		case CHR.fileExtension:
//			return try data.read(CHR.self)
//		case DAL.fileExtension:
//			return try data.read(DAL.self)
//		case DCL.fileExtension:
//			return try data.read(DCL.self)
		case DEX.fileExtension:
			return try data.read(DEX.self)
		case DMG.fileExtension:
			return try data.read(DMG.self)
		case DMS.fileExtension:
			return try data.read(DMS.self)
//		case DNC.fileExtension:
//			return try data.DNC(DMS.self)
		case DTX.fileExtension:
			return try data.read(DTX.self)
//		case MFS.fileExtension:
//			return try data.read(MFS.self)
		case MM3.fileExtension:
			return try data.read(MM3.self)
//		case MMS.fileExtension: // TODO: doesnt work for repacking due to .bin and MAR standalone name stuff
//			return try data.read(MMS.self)
		case MPM.fileExtension:
			return try data.read(MPM.self)
		case RLS.fileExtension:
			return try data.read(RLS.self)
//		case SHP.fileExtension:
//			return try data.read(SHP.self)
		default: ()
	}
	
	let marker = data.placeMarker()
	let magicBytes = (try? data.read(String.self, length: 3)) ?? ""
	data.jump(to: marker)
	
	return switch magicBytes {
//		case AIS.Binary.magicBytes:
//			try data.read(AIS.Binary.self)
//		case AST.Binary.magicBytes:
//			try data.read(AST.Binary.self)
//		case CHR.Binary.magicBytes:
//			try data.read(CHR.Binary.self)
//		case DAL.Binary.magicBytes:
//			try data.read(DAL.Binary.self)
//		case DCL.Binary.magicBytes:
//			try data.read(DCL.Binary.self)
		case DEX.Binary.magicBytes:
			try data.read(DEX.Binary.self)
		case DMG.Binary.magicBytes:
			try data.read(DMG.Binary.self)
		case DMS.Binary.magicBytes:
			try data.read(DMS.Binary.self)
//		case DNC.Binary.magicBytes:
//			try data.read(DNC.Binary.self)
		case DTX.Binary.magicBytes:
			try data.read(DTX.Binary.self)
//		case MFS.Binary.magicBytes:
//			try data.read(MFS.Binary.self)
		case MM3.Binary.magicBytes:
			try data.read(MM3.Binary.self)
//		case MMS.Binary.magicBytes:
//			try data.read(MMS.Binary.self)
		case MPM.Binary.magicBytes:
			try data.read(MPM.Binary.self)
		case RLS.Binary.magicBytes:
			try data.read(RLS.Binary.self)
//		case SHP.Binary.magicBytes:
//			try data.read(SHP.Binary.self)
		default:
			nil
	}
}

extension ProprietaryFileData where Self: Codable {
	init(_ data: Datastream) throws {
		assert(data.offset == 0) // should only read full files as json (?)
		self = try JSONDecoder().decode(Self.self, from: Data(data.bytes))
	}
	
	func write(to data: Datawriter) {
		// TODO: panic bad here?
		let jsonData = try! JSONEncoder(.prettyPrinted).encode(self)
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
	static let packedStatus: PackedStatus = .unknown
}
