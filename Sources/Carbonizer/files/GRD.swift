import BinaryParser

// map c zooms the camera ? and maybe more?
// map g may have something to do with the rocks that spawn in digsites

enum GRD {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "GRD"
		
		var width: UInt32
		var height: UInt32
		
		var numberOfBytes: UInt32
		var offset: UInt32
		
		@Offset(givenBy: \Self.offset)
		@Length(givenBy: \Self.numberOfBytes)
		var gridData: Datastream
	}
	
	struct Unpacked: Codable {}
}

// MARK: packed
extension GRD.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> GRD.Unpacked {
		GRD.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: GRD.Unpacked, configuration: CarbonizerConfiguration) {
		todo()
	}
}

// MARK: unpacked
extension GRD.Unpacked: ProprietaryFileData {
	static let fileExtension = ".grd.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> GRD.Packed {
		GRD.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: GRD.Packed, configuration: CarbonizerConfiguration) {
		todo()
	}
}

