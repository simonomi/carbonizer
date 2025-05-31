import BinaryParser

enum DML {
	@BinaryConvertible
	struct Packed {
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
	
	struct Unpacked: Codable {}
}

// MARK: packed
extension DML.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> DML.Unpacked {
		DML.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: DML.Unpacked, configuration: CarbonizerConfiguration) {
		todo()
	}
}

// MARK: unpacked
extension DML.Unpacked: ProprietaryFileData {
	static let fileExtension = ".dml.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> DML.Packed {
		DML.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: DML.Packed, configuration: CarbonizerConfiguration) {
		todo()
	}
}
