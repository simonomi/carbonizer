import BinaryParser

struct HML {
	var masks: [Mask]
	
	struct Mask: Codable {
		var name: UInt16
		var japaneseDebugName: UInt16
		
		var price: Int32
		var walkingSoundEffect: Int32
		var runningSoundEffect: Int32
		
		var modelName: String
	}
	
	@BinaryConvertible
	struct Binary {
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
}

extension HML: ProprietaryFileData, BinaryConvertible, Codable {
	static let fileExtension = ".hml.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	init(_ binary: Binary, configuration: CarbonizerConfiguration) {
		masks = binary.masks.map(Mask.init)
	}
}

extension HML.Mask {
	init(_ binary: HML.Binary.Mask) {
		name = binary.name
		japaneseDebugName = binary.japaneseDebugName
		
		price = binary.price
		walkingSoundEffect = binary.walkingSoundEffect
		runningSoundEffect = binary.runningSoundEffect
		
		modelName = binary.modelName
	}
}

extension HML.Binary: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	init(_ hml: HML, configuration: CarbonizerConfiguration) {
		masks = hml.masks.map(Mask.init)
		maskCount = UInt32(masks.count)
		maskOffsets = makeOffsets(
			start: maskOffsetsOffset + maskCount * 4,
			sizes: masks.map { $0.size() },
			alignedTo: 4
		)
	}
}

extension HML.Binary.Mask {
	init(_ binary: HML.Mask) {
		name = binary.name
		japaneseDebugName = binary.japaneseDebugName
		
		price = binary.price
		walkingSoundEffect = binary.walkingSoundEffect
		runningSoundEffect = binary.runningSoundEffect
		
		modelName = binary.modelName
	}
	
	func size() -> UInt32 {
		modelNameOffset + UInt32(modelName.utf8CString.count)
	}
}
