import BinaryParser

enum HML {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "HML"
		
		var maskCount: UInt32
		var maskOffsetsOffset: UInt32 = 0xC
		
		@Count(givenBy: \Self.maskCount)
		@Offset(givenBy: \Self.maskOffsetsOffset)
		var maskOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.maskOffsets)
		var masks: [Mask]
		
		@BinaryConvertible
		struct Mask {
			var name: UInt16
			var japaneseDebugName: UInt16
			
			var price: Int32
			
			var modelNameOffset: UInt32 = 0x14
			
			var walkingSoundEffect: Int32
			var runningSoundEffect: Int32
			
			@Offset(givenBy: \Self.modelNameOffset)
			var modelName: String
		}
	}
	
	struct Unpacked {
		var masks: [Mask]
		
		struct Mask: Codable {
			var name: UInt16
			var japaneseDebugName: UInt16
			
			var _name: String?
			var _japaneseDebugName: String?
			
			var price: Int32
			var walkingSoundEffect: Int32
			var runningSoundEffect: Int32
			
			var modelName: String
		}
	}
}

// MARK: packed
extension HML.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> HML.Unpacked {
		HML.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: HML.Unpacked, configuration: CarbonizerConfiguration) {
		masks = unpacked.masks.map(Mask.init)
		maskCount = UInt32(masks.count)
		maskOffsets = makeOffsets(
			start: maskOffsetsOffset + maskCount * 4,
			sizes: masks.map(\.size),
			alignedTo: 4
		)
	}
}

extension HML.Packed.Mask {
	init(_ unpacked: HML.Unpacked.Mask) {
		name = unpacked.name
		japaneseDebugName = unpacked.japaneseDebugName
		
		price = unpacked.price
		walkingSoundEffect = unpacked.walkingSoundEffect
		runningSoundEffect = unpacked.runningSoundEffect
		
		modelName = unpacked.modelName
	}
	
	var size: UInt32 {
		modelNameOffset + UInt32(modelName.utf8CString.count)
	}
}

// MARK: unpacked
extension HML.Unpacked: ProprietaryFileData {
	static let fileExtension = ".hml.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> HML.Packed {
		HML.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: HML.Packed, configuration: CarbonizerConfiguration) {
		masks = packed.masks.map(Mask.init)
	}
}

extension HML.Unpacked.Mask {
	init(_ packed: HML.Packed.Mask) {
		name = packed.name
		japaneseDebugName = packed.japaneseDebugName
		
		price = packed.price
		walkingSoundEffect = packed.walkingSoundEffect
		runningSoundEffect = packed.runningSoundEffect
		
		modelName = packed.modelName
	}
}

// MARK: unpacked codable
extension HML.Unpacked: Codable {
	init(from decoder: any Decoder) throws {
		masks = try [Mask](from: decoder)
	}
	
	func encode(to encoder: any Encoder) throws {
		try masks.encode(to: encoder)
	}
}
