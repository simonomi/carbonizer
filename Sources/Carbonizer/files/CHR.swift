import BinaryParser

enum CHR {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "CHR"
		
		var bodyNamesCount: UInt32
		var bodyNamesOffset: UInt32 = 0x64
		
		var headNamesCount: UInt32
		var headNamesOffset: UInt32
		
		@Count(16)
		var unknowns: [Int32]
		
		var someBodyCount: UInt32
		var someBodyOffset: UInt32
		var someHeadCount: UInt32
		var someHeadOffset: UInt32
		
		@Count(givenBy: \Self.bodyNamesCount)
		@Offset(givenBy: \Self.bodyNamesOffset)
		var bodyNamesOffsets: [UInt32]
		@Offsets(givenBy: \Self.bodyNamesOffsets)
		var bodyNames: [String]
		
		@Count(givenBy: \Self.headNamesCount)
		@Offset(givenBy: \Self.headNamesOffset)
		var headNamesOffsets: [UInt32]
		@Offsets(givenBy: \Self.headNamesOffsets)
		var headNames: [String]
		
		@Count(givenBy: \Self.someBodyCount)
		@Offset(givenBy: \Self.someBodyOffset)
		var someBodies: [UInt16]
		
		@Count(givenBy: \Self.someHeadCount)
		@Offset(givenBy: \Self.someHeadOffset)
		var someHeads: [UInt16]
	}
	
	struct Unpacked: Codable {}
}

// MARK: packed
extension CHR.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> CHR.Unpacked {
		CHR.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: CHR.Unpacked, configuration: CarbonizerConfiguration) {
		todo()
	}
}

// MARK: unpacked
extension CHR.Unpacked: ProprietaryFileData {
	static let fileExtension = ".chr.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> CHR.Packed {
		CHR.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: CHR.Packed, configuration: CarbonizerConfiguration) {
		todo()
	}
}
