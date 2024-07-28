import BinaryParser

struct CHR {
	@BinaryConvertible
	struct Binary {
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
}

extension CHR: ProprietaryFileData, Codable {
	static let fileExtension = "chr.json"
	static let packedStatus: PackedStatus = .unpacked
	
	init(_ binary: Binary) {
		fatalError("TODO:")
	}
	
	enum CodingKeys: CodingKey {
		// TODO: custom keys ?
	}
}

extension CHR.Binary: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	init(_ chr: CHR) {
		fatalError("TODO:")
	}
}
