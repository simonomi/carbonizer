import BinaryParser

struct BBG {
	var kasekiums: [Kasekium]
	
	struct Kasekium: Codable {
		var index: Int32
		
		var imageFile: String
		
		var modelFile: String
	}
	
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "BBG"
		
		var kasekiumCount: UInt32
		var kasekiumOffsetsOffset: UInt32 = 0xC
		
		@Count(givenBy: \Self.kasekiumCount)
		@Offset(givenBy: \Self.kasekiumOffsetsOffset)
		var kasekiumOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.kasekiumOffsets)
		var kasekiums: [Kasekium]
		
		@BinaryConvertible
		struct Kasekium {
			var index: Int32
			
			var imageFileOffset: UInt32 = 0xC
			var modelFileOffset: UInt32
			
			@Offset(givenBy: \Self.imageFileOffset)
			var imageFile: String
			
			@Offset(givenBy: \Self.modelFileOffset)
			var modelFile: String
		}
	}
}

extension BBG: ProprietaryFileData, BinaryConvertible {
	static let fileExtension = ".bbg.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	init(_ binary: Binary, configuration: CarbonizerConfiguration) {
		kasekiums = binary.kasekiums.map(Kasekium.init)
	}
}

extension BBG.Kasekium {
	init(_ binary: BBG.Binary.Kasekium) {
		index = binary.index
		imageFile = binary.imageFile
		modelFile = binary.modelFile
	}
}

extension BBG.Binary: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	init(_ bbg: BBG, configuration: CarbonizerConfiguration) {
		kasekiums = bbg.kasekiums.map(Kasekium.init)
		kasekiumCount = UInt32(kasekiums.count)
		kasekiumOffsets = makeOffsets(
			start: kasekiumOffsetsOffset + kasekiumCount * 4,
			sizes: kasekiums.map { $0.size() },
			alignedTo: 4
		)
	}
}

extension BBG.Binary.Kasekium {
	init(_ kasekium: BBG.Kasekium) {
		index = kasekium.index
		imageFile = kasekium.imageFile
		modelFile = kasekium.modelFile
		modelFileOffset = imageFileOffset + UInt32(imageFile.utf8CString.count.roundedUpToTheNearest(4))
	}
	
	func size() -> UInt32 {
		modelFileOffset + UInt32(modelFile.utf8CString.count)
	}
}

extension BBG: Codable {
	init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		kasekiums = try container.decode([BBG.Kasekium].self)
	}
	
	func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(kasekiums)
	}
}


