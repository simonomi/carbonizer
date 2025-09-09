import BinaryParser

enum DSL {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "DSL"
		
		var haikuCount: UInt32
		var haikuOffsetsOffset: UInt32 = 0xC
		
		@Count(givenBy: \Self.haikuCount)
		@Offset(givenBy: \Self.haikuOffsetsOffset)
		var haikuOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.haikuOffsets)
		var haiku: [Haiku]
		
		@BinaryConvertible
		struct Haiku {
			var colorOffset: UInt32 = 0x8
			var haikuOffset: UInt32 = 0xC
			
			@Count(3)
			@Offset(givenBy: \Self.colorOffset)
			var color: [UInt8]
			
			@Offset(givenBy: \Self.haikuOffset)
			var haiku: String
			
			@FourByteAlign
			var fourByteAlign: ()
		}
	}
	
	struct Unpacked: Codable {
		var haiku: [Haiku]
		
		struct Haiku: Codable {
			var color: Color
			var haiku: String
		}
	}
}

// MARK: packed
extension DSL.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> DSL.Unpacked {
		DSL.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: DSL.Unpacked, configuration: CarbonizerConfiguration) {
		haikuCount = UInt32(unpacked.haiku.count)
		haiku = unpacked.haiku.map(Haiku.init)
		haikuOffsets = makeOffsets(
			start: haikuOffsetsOffset + haikuCount * 4,
			sizes: haiku.map(\.size)
		)
	}
}

extension DSL.Packed.Haiku {
	fileprivate init(_ unpacked: DSL.Unpacked.Haiku) {
		color = unpacked.color.bytes
		haiku = unpacked.haiku
	}
	
	var size: UInt32 {
		haikuOffset + UInt32(haiku.utf8CString.count.roundedUpToTheNearest(4))
	}
}

// MARK: unpacked
extension DSL.Unpacked: ProprietaryFileData {
	static let fileExtension = ".dsl.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> DSL.Packed {
		DSL.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: DSL.Packed, configuration: CarbonizerConfiguration) {
		haiku = packed.haiku.map(Haiku.init)
	}
}

extension DSL.Unpacked.Haiku {
	fileprivate init(_ packed: DSL.Packed.Haiku) {
		color = Color(packed.color)
		haiku = packed.haiku
	}
}
