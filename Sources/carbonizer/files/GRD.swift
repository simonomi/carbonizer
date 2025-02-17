import BinaryParser

// map c zooms the camera ? and maybe more?
// map g may have something to do with the rocks that spawn in digsites

struct GRD {
	@BinaryConvertible
	struct Binary {
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
}

extension GRD: ProprietaryFileData, BinaryConvertible, Codable {
	static let fileExtension = ".grd.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	init(_ binary: Binary, configuration: CarbonizerConfiguration) {
		todo()
	}
}

extension GRD.Binary: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	init(_ grd: GRD, configuration: CarbonizerConfiguration) {
		todo()
	}
}

