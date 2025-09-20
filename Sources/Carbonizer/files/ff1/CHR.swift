import BinaryParser

enum CHR {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "CHR"
		
		var bodyNamesCount: UInt32
		var bodyNamesOffsetsOffset: UInt32 = 0x64
		
		var headNamesCount: UInt32
		var headNamesOffsetsOffset: UInt32
		
		@Count(16)
		var unknowns: [Int32]
		
		var someBodyCount: UInt32
		var someBodiesOffset: UInt32
		var someHeadCount: UInt32
		var someHeadsOffset: UInt32
		
		@Count(givenBy: \Self.bodyNamesCount)
		@Offset(givenBy: \Self.bodyNamesOffsetsOffset)
		var bodyNamesOffsets: [UInt32]
		@Offsets(givenBy: \Self.bodyNamesOffsets)
		var bodyNames: [String]
		
		@Count(givenBy: \Self.headNamesCount)
		@Offset(givenBy: \Self.headNamesOffsetsOffset)
		var headNamesOffsets: [UInt32]
		@Offsets(givenBy: \Self.headNamesOffsets)
		var headNames: [String]
		
		@Count(givenBy: \Self.someBodyCount)
		@Offset(givenBy: \Self.someBodiesOffset)
		var someBodies: [UInt16]
		
		@Count(givenBy: \Self.someHeadCount)
		@Offset(givenBy: \Self.someHeadsOffset)
		var someHeads: [UInt16]
	}
	
	struct Unpacked: Codable {
		var unknowns: [Double]
		
		var bodyNames: [String]
		var headNames: [String]
		var someBodies: [UInt16]
		var someHeads: [UInt16]
	}
}

// MARK: packed
extension CHR.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> CHR.Unpacked {
		CHR.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: CHR.Unpacked, configuration: Configuration) {
		bodyNamesCount = UInt32(unpacked.bodyNames.count)
		
		headNamesCount = UInt32(unpacked.headNames.count)
		headNamesOffsetsOffset = bodyNamesOffsetsOffset + (bodyNamesCount * 4) + UInt32(
			unpacked.bodyNames.map { $0.utf8CString.count }.sum().roundedUpToTheNearest(4)
		)
		
		unknowns = unpacked.unknowns.map { Int32(fixedPoint: $0) }
		
		someBodyCount = UInt32(unpacked.someBodies.count)
		someBodiesOffset = headNamesOffsetsOffset + (headNamesCount * 4) + UInt32(
			unpacked.headNames.map { $0.utf8CString.count }.sum().roundedUpToTheNearest(4)
		)
		someHeadCount = UInt32(unpacked.someHeads.count)
		someHeadsOffset = someBodiesOffset + (someBodyCount * 2) // TODO: rounded to 4?
		                                                         // there's always an even number of someBodies, so i guess it's not possible...?
		
		bodyNamesOffsets = makeOffsets(
			start: bodyNamesOffsetsOffset + (bodyNamesCount * 4),
			sizes: unpacked.bodyNames.map { UInt32($0.utf8CString.count) }
		)
		bodyNames = unpacked.bodyNames
		
		headNamesOffsets = makeOffsets(
			start: headNamesOffsetsOffset + (headNamesCount * 4),
			sizes: unpacked.headNames.map { UInt32($0.utf8CString.count) }
		)
		headNames = unpacked.headNames
		
		someBodies = unpacked.someBodies
		
		someHeads = unpacked.someHeads
	}
}

// MARK: unpacked
extension CHR.Unpacked: ProprietaryFileData {
	static let fileExtension = ".chr.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: Configuration) -> CHR.Packed {
		CHR.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: CHR.Packed, configuration: Configuration) {
		unknowns = packed.unknowns.map { Double(fixedPoint: $0) }
		
		bodyNames = packed.bodyNames
		headNames = packed.headNames
		someBodies = packed.someBodies
		someHeads = packed.someHeads
	}
}
