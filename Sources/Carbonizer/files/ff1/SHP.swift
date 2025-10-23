import BinaryParser

enum SHP {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "SHP"
		var firstCount: UInt32
		var firstOffset: UInt32 = 0x14
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
	
	struct Unpacked: Codable {
		var firsts: [UInt32]
		var seconds: [UInt32]
	}
}

// MARK: packed
extension SHP.Packed: ProprietaryFileData {
	static let fileExtension = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> SHP.Unpacked {
		SHP.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: SHP.Unpacked, configuration: Configuration) {
		firstCount = UInt32(unpacked.firsts.count)
		secondCount = UInt32(unpacked.seconds.count)
		secondOffset = firstOffset + 8 * firstCount
		
		firsts = unpacked.firsts.map { Entry(unknown2: $0) }
		
		seconds = unpacked.seconds.map { Entry(unknown2: $0) }
	}
}

// MARK: unpacked
extension SHP.Unpacked: ProprietaryFileData {
	static let fileExtension = ".shp.json"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> SHP.Packed {
		SHP.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: SHP.Packed, configuration: Configuration) {
		firsts = packed.firsts.map(\.unknown2)
		seconds = packed.seconds.map(\.unknown2)
	}
}
