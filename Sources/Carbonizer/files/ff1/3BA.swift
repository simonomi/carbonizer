import BinaryParser

enum TBA {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "3BA"
		
		var count: UInt32
		var offset: UInt32 = 0xC
		
		@Count(givenBy: \Self.count)
		@Offset(givenBy: \Self.offset)
		var words: [UInt8]
	}
	
	struct Unpacked {
		var data: [UInt8]
	}
}

// MARK: packed
extension TBA.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: Carbonizer.Configuration) -> Self { self }
	
	func unpacked(configuration: Carbonizer.Configuration) -> TBA.Unpacked {
		TBA.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: TBA.Unpacked, configuration: Carbonizer.Configuration) {
		count = UInt32(unpacked.data.count)
		words = unpacked.data
	}
}

// MARK: unpacked
extension TBA.Unpacked: ProprietaryFileData {
	static let fileExtension = ".3ba.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: Carbonizer.Configuration) -> TBA.Packed {
		TBA.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Carbonizer.Configuration) -> Self { self }
	
	fileprivate init(_ packed: TBA.Packed, configuration: Carbonizer.Configuration) {
		data = packed.words
	}
}

extension TBA.Unpacked: Codable {
	init(from decoder: any Decoder) throws {
		data = try [UInt8](from: decoder)
	}
	
	func encode(to encoder: any Encoder) throws {
		try data.encode(to: encoder)
	}
}
