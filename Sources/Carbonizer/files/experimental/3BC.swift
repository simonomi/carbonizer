import BinaryParser

// model/battle/arcscenecsv.mar/0000
enum TBC { // 3BC
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "TBC"
		
		var unknownCount: UInt32
		var unknownsOffset: UInt32
		
		var archiveNameOffset: UInt32
		
		@Count(givenBy: \Self.unknownCount)
		@Offset(givenBy: \Self.unknownsOffset)
		var unknowns: [UInt32]
		
		@Offset(givenBy: \Self.archiveNameOffset)
		var archiveName: String
	}
	
	struct Unpacked: Codable {}
}

// MARK: packed
extension TBC.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> TBC.Unpacked {
		TBC.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: TBC.Unpacked, configuration: Configuration) {
		todo()
	}
}

// MARK: unpacked
extension TBC.Unpacked: ProprietaryFileData {
	static let fileExtension = ".3bc.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: Configuration) -> TBC.Packed {
		TBC.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: TBC.Packed, configuration: Configuration) {
		todo()
	}
}
