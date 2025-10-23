import BinaryParser

// btl_tutorial/*
enum DBT {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "DBT"
		
		var thingCount: UInt32
		var thingOffsetsOffset: UInt32 = 0xC
		
		@Count(givenBy: \Self.thingCount)
		@Offset(givenBy: \Self.thingOffsetsOffset)
		var thingOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.thingOffsets)
		var things: [Thing]
		
		@BinaryConvertible
		struct Thing {
			var count: UInt32
			var offset: UInt32 = 0x8
			
			@Count(givenBy: \Self.count)
			@Offset(givenBy: \Self.offset)
			var items: [Int32] // in ffc, these are i16s, otherwise the same (i think)
		}
	}
	
	struct Unpacked {
		var things: [[Int32]]
	}
}

// MARK: packed
extension DBT.Packed: ProprietaryFileData {
	static let fileExtension = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> DBT.Unpacked {
		DBT.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: DBT.Unpacked, configuration: Configuration) {
		thingCount = UInt32(unpacked.things.count)
		
		things = unpacked.things.map(Thing.init)
		
		thingOffsets = makeOffsets(
			start: thingOffsetsOffset + thingCount * 4,
			sizes: things.map(\.size)
		)
	}
}

extension DBT.Packed.Thing {
	fileprivate init(_ unpacked: [Int32]) {
		count = UInt32(unpacked.count)
		items = unpacked
	}
	
	fileprivate var size: UInt32 {
		8 + count * 4
	}
}

// MARK: unpacked
extension DBT.Unpacked: ProprietaryFileData {
	static let fileExtension = ".dbt.json"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> DBT.Packed {
		DBT.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: DBT.Packed, configuration: Configuration) {
		things = packed.things.map(\.items)
	}
}

extension DBT.Unpacked: Codable {
	init(from decoder: any Decoder) throws {
		things = try [[Int32]](from: decoder)
	}
	
	func encode(to encoder: any Encoder) throws {
		try things.encode(to: encoder)
	}
}
