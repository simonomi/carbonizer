import BinaryParser

enum KIL {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "KIL"
		
		var keyItemCount: UInt32
		var keyItemOffset: UInt32 = 0xC
		
		@Count(givenBy: \Self.keyItemCount)
		@Offset(givenBy: \Self.keyItemOffset)
		var keyItems: [KeyItem]
		
		@BinaryConvertible
		struct KeyItem {
			var nameIndex: UInt16
			var descriptionIndex: UInt16
			var unknown: UInt32 = 0
		}
	}
	
	struct Unpacked {
		var keyItems: [KeyItem?]
		
		struct KeyItem: Codable {
			var nameIndex: UInt16
			var descriptionIndex: UInt16
			
			var _index: Int?
			var _name: String?
			var _description: String?
		}
	}
}

// MARK: packed
extension KIL.Packed: ProprietaryFileData {
	static let fileExtension = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> KIL.Unpacked {
		KIL.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: KIL.Unpacked, configuration: Configuration) {
		keyItems = unpacked.keyItems.map(KeyItem.init)
		keyItemCount = UInt32(keyItems.count)
	}
}

extension KIL.Packed.KeyItem {
	init(_ unpacked: KIL.Unpacked.KeyItem?) {
		nameIndex = unpacked?.nameIndex ?? 0
		descriptionIndex = unpacked?.descriptionIndex ?? 0
	}
}

// MARK: unpacked
extension KIL.Unpacked: ProprietaryFileData {
	static let fileExtension = ".kil.json"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> KIL.Packed {
		KIL.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: KIL.Packed, configuration: Configuration) {
		keyItems = packed.keyItems.enumerated().map(KeyItem.init)
	}
}

extension KIL.Unpacked.KeyItem {
	init?(_ index: Int, _ packed: KIL.Packed.KeyItem) {
		guard packed.nameIndex != 0, packed.descriptionIndex != 0 else { return nil }
		
		nameIndex = packed.nameIndex
		descriptionIndex = packed.descriptionIndex
		
		_index = index
	}
}

// MARK: unpacked codable
extension KIL.Unpacked: Codable {
	init(from decoder: any Decoder) throws {
		keyItems = try [KIL.Unpacked.KeyItem?](from: decoder)
	}
	
	func encode(to encoder: any Encoder) throws {
		try keyItems.encode(to: encoder)
	}
}
