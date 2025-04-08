import BinaryParser

struct DML {
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "DML"
		
		var vivosaurCount: UInt32
		var vivosaurOffset: UInt32
		
		@Count(givenBy: \Self.vivosaurCount)
		@Offset(givenBy: \Self.vivosaurOffset)
		var vivosaurs: [Vivosaur]
		
		@BinaryConvertible
		struct Vivosaur {
			var description: Int32
			
			var unknown1: UInt8
			var size: UInt8
			var site: UInt8
			var unknown4: UInt8
			var unknown5: UInt8
			var unknown6: UInt8
			var unknown7: UInt8
			var era: UInt8
		}
	}
}

extension DML: ProprietaryFileData, BinaryConvertible, Codable {
	static let fileExtension = ".dml.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	init(_ binary: Binary, configuration: CarbonizerConfiguration) {
		todo()
	}
}

extension DML.Binary: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	init(_ dml: DML, configuration: CarbonizerConfiguration) {
		todo()
	}
}

