import BinaryParser

struct KIL {
	var keyItems: [KeyItem?]
	
	struct KeyItem: Codable {
		var index1: UInt16
		var index2: UInt16
		
		// TODO: kilLabeller
		var _label1: String?
		var _label2: String?
	}
	
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "KIL"
		
		var keyItemCount: UInt32
		var keyItemOffset: UInt32 = 0xC
		
		@Count(givenBy: \Self.keyItemCount)
		@Offset(givenBy: \Self.keyItemOffset)
		var keyItems: [KeyItem]
		
		@BinaryConvertible
		struct KeyItem {
			var index1: UInt16
			var index2: UInt16
			var unknown: UInt32 = 0
		}
	}
}

extension KIL: ProprietaryFileData, BinaryConvertible {
	static let fileExtension = ".kil.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	init(_ binary: Binary, configuration: CarbonizerConfiguration) {
		keyItems = binary.keyItems.map(KeyItem.init)
	}
}

extension KIL.KeyItem {
	init?(_ binary: KIL.Binary.KeyItem) {
		guard binary.index1 != 0, binary.index2 != 0 else { return nil }
		
		index1 = binary.index1
		index2 = binary.index2
	}
}

extension KIL.Binary: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	init(_ kil: KIL, configuration: CarbonizerConfiguration) {
		keyItems = kil.keyItems.map(KeyItem.init)
		keyItemCount = UInt32(keyItems.count)
	}
}

extension KIL.Binary.KeyItem {
	init(_ keyItem: KIL.KeyItem?) {
		index1 = keyItem?.index1 ?? 0
		index2 = keyItem?.index2 ?? 0
	}
}

extension KIL: Codable {
	init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		keyItems = try container.decode([KIL.KeyItem?].self)
	}
	
	func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(keyItems)
	}
}
