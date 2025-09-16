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
			var index1: UInt16
			var index2: UInt16
			var unknown: UInt32 = 0
		}
	}
	
	struct Unpacked {
		var keyItems: [KeyItem?]
		
		struct KeyItem: Codable {
			var index1: UInt16
			var index2: UInt16
			
			// TODO: kilLabeller
			var _label1: String?
			var _label2: String?
		}
	}
}

// MARK: packed
extension KIL.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> KIL.Unpacked {
		KIL.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: KIL.Unpacked, configuration: CarbonizerConfiguration) {
		keyItems = unpacked.keyItems.map(KeyItem.init)
		keyItemCount = UInt32(keyItems.count)
	}
}

extension KIL.Packed.KeyItem {
	init(_ unpacked: KIL.Unpacked.KeyItem?) {
		index1 = unpacked?.index1 ?? 0
		index2 = unpacked?.index2 ?? 0
	}
}

// MARK: unpacked
extension KIL.Unpacked: ProprietaryFileData {
	static let fileExtension = ".kil.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> KIL.Packed {
		KIL.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: KIL.Packed, configuration: CarbonizerConfiguration) {
		keyItems = packed.keyItems.map(KeyItem.init)
	}
}

extension KIL.Unpacked.KeyItem {
	init?(_ packed: KIL.Packed.KeyItem) {
		guard packed.index1 != 0, packed.index2 != 0 else { return nil }
		
		index1 = packed.index1
		index2 = packed.index2
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
