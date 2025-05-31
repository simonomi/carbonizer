import BinaryParser

enum SHP {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "SHP"
		var firstCount: UInt32
		var firstOffset: UInt32
		var secondCount: UInt32
		var secondOffset: UInt32
		
		@Count(givenBy: \Self.firstCount)
		@Offset(givenBy: \Self.firstOffset)
		var firsts: [Entry]
		
		@Count(givenBy: \Self.secondCount)
		@Offset(givenBy: \Self.secondOffset)
		var seconds: [Entry]
		
		@BinaryConvertible
		struct Entry {
			var unknown1: UInt32 = 0
			var unknown2: UInt32
		}
	}
	
	struct Unpacked: Codable {}
}

// MARK: packed
extension SHP.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> SHP.Unpacked {
		SHP.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: SHP.Unpacked, configuration: CarbonizerConfiguration) {
		todo()
	}
}

// MARK: unpacked
extension SHP.Unpacked: ProprietaryFileData {
	static let fileExtension = ".shp.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> SHP.Packed {
		SHP.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: SHP.Packed, configuration: CarbonizerConfiguration) {
		todo()
	}
}
