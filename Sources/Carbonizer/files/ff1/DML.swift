import BinaryParser

enum DML {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "DML"
		
		var vivosaurCount: UInt32
		var vivosaursOffset: UInt32 = 0xC
		
		@Count(givenBy: \Self.vivosaurCount)
		@Offset(givenBy: \Self.vivosaursOffset)
		var vivosaurs: [Vivosaur]
		
		@BinaryConvertible
		struct Vivosaur {
			var unknown: UInt32 = 0
			
			var descriptionIndex: Int32
			
			var unknown1: UInt8
			
			var sortSize: UInt8
			var sortSite: UInt8
			
			var unknown4: UInt8 = 0
			
			// same for all legendaries
			var unknown5: UInt8 // 0, 0x40, 0x80, 0xa0
			var unknown6: UInt8
			var unknown7: UInt8
			
			var sortEra: UInt8
		}
	}
	
	struct Unpacked {
		var vivosaurs: [Vivosaur]
		
		struct Vivosaur: Codable {
			var _name: String?
			var _description: String?
			
			var descriptionIndex: Int32
			
			var unknown1: UInt8
			
			var sortSize: UInt8
			var sortSite: UInt8
			
			var unknown5: UInt8
			var unknown6: UInt8
			var unknown7: UInt8
			
			var sortEra: UInt8
		}
	}
}

// MARK: packed
extension DML.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> DML.Unpacked {
		DML.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: DML.Unpacked, configuration: CarbonizerConfiguration) {
		vivosaurs = unpacked.vivosaurs.map(Vivosaur.init)
		vivosaurCount = UInt32(vivosaurs.count)
	}
}

extension DML.Packed.Vivosaur {
	fileprivate init(_ unpacked: DML.Unpacked.Vivosaur) {
		descriptionIndex = unpacked.descriptionIndex
		
		unknown1 = unpacked.unknown1
		
		sortSize = unpacked.sortSize
		sortSite = unpacked.sortSite
		
		unknown5 = unpacked.unknown5
		unknown6 = unpacked.unknown6
		unknown7 = unpacked.unknown7
		
		sortEra = unpacked.sortEra
	}
}

// MARK: unpacked
extension DML.Unpacked: ProprietaryFileData {
	static let fileExtension = ".dml.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> DML.Packed {
		DML.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: DML.Packed, configuration: CarbonizerConfiguration) {
		vivosaurs = packed.vivosaurs.enumerated().map(Vivosaur.init)
	}
}

extension DML.Unpacked.Vivosaur {
	fileprivate init(_ index: Int, _ unpacked: DML.Packed.Vivosaur) {
		_name = vivosaurNames[Int32(index)]
		
		descriptionIndex = unpacked.descriptionIndex
		
		unknown1 = unpacked.unknown1
		
		sortSize = unpacked.sortSize
		sortSite = unpacked.sortSite
		
		unknown5 = unpacked.unknown5
		unknown6 = unpacked.unknown6
		unknown7 = unpacked.unknown7
		
		sortEra = unpacked.sortEra
	}
}

// MARK: unpacked codable
extension DML.Unpacked: Codable {
	init(from decoder: any Decoder) throws {
		vivosaurs = try [Vivosaur](from: decoder)
	}
	
	func encode(to encoder: any Encoder) throws {
		try vivosaurs.encode(to: encoder)
	}
}
