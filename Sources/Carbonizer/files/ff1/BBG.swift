import BinaryParser

enum BBG {
	@BinaryConvertible
	struct Packed {
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
	
	struct Unpacked {
		var kasekiums: [Kasekium]
		
		struct Kasekium: Codable {
			var index: Int32
			
			var imageFile: String
			
			var modelFile: String
		}
	}
}

// MARK: packed
extension BBG.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> BBG.Unpacked {
		BBG.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: BBG.Unpacked, configuration: CarbonizerConfiguration) {
		kasekiums = unpacked.kasekiums.map(Kasekium.init)
		kasekiumCount = UInt32(kasekiums.count)
		kasekiumOffsets = makeOffsets(
			start: kasekiumOffsetsOffset + kasekiumCount * 4,
			sizes: kasekiums.map { $0.size() },
			alignedTo: 4
		)
	}
}

extension BBG.Packed.Kasekium {
	init(_ unpacked: BBG.Unpacked.Kasekium) {
		index = unpacked.index
		imageFile = unpacked.imageFile
		modelFile = unpacked.modelFile
		modelFileOffset = imageFileOffset + UInt32(imageFile.utf8CString.count.roundedUpToTheNearest(4))
	}
	
	func size() -> UInt32 {
		modelFileOffset + UInt32(modelFile.utf8CString.count)
	}
}

// MARK: unpacked
extension BBG.Unpacked: ProprietaryFileData {
	static let fileExtension = ".bbg.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> BBG.Packed {
		BBG.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: BBG.Packed, configuration: CarbonizerConfiguration) {
		kasekiums = packed.kasekiums.map(Kasekium.init)
	}
}

extension BBG.Unpacked.Kasekium {
	init(_ packed: BBG.Packed.Kasekium) {
		index = packed.index
		imageFile = packed.imageFile
		modelFile = packed.modelFile
	}
}

// MARK: unpacked codable
extension BBG.Unpacked: Codable {
	init(from decoder: any Decoder) throws {
		kasekiums = try [BBG.Unpacked.Kasekium](from: decoder)
	}
	
	func encode(to encoder: any Encoder) throws {
		try kasekiums.encode(to: encoder)
	}
}
