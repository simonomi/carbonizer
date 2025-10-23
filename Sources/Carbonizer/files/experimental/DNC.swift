import BinaryParser

// ff1-only
enum DNC {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "DNC"
		
		var unknown1: UInt32
		var unknown2: UInt32 = 0x3C // 60
		
		var firstCount: UInt32
		var firstOffset: UInt32 = 0x24
		
		var secondCount: UInt32
		var secondOffset: UInt32
		
		var thirdCount: UInt32
		var thirdOffset: UInt32
		
		@Count(givenBy: \Self.firstCount)
		@Offset(givenBy: \Self.firstOffset)
		var firsts: [UInt32]
		
		@Count(givenBy: \Self.secondCount)
		@Offset(givenBy: \Self.secondOffset)
		var seconds: [Second]
		
		@Count(givenBy: \Self.thirdCount)
		@Offset(givenBy: \Self.thirdOffset)
		var thirds: [Third]
		
		@BinaryConvertible
		struct Second {
			var unknown1: UInt32
			var unknown2: UInt32
			var unknown3: UInt32
		}
		
		@BinaryConvertible
		struct Third {
			var unknown1: UInt32
			var unknown2: UInt32
		}
	}
	
	struct Unpacked: Codable {}
}

// MARK: packed
extension DNC.Packed: ProprietaryFileData {
	static let fileExtension = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> DNC.Unpacked {
		DNC.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: DNC.Unpacked, configuration: Configuration) {
		todo()
	}
}

// MARK: unpacked
extension DNC.Unpacked: ProprietaryFileData {
	static let fileExtension = ".dnc.json"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> DNC.Packed {
		DNC.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: DNC.Packed, configuration: Configuration) {
		todo()
	}
}
