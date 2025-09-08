import BinaryParser

enum KPS {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "KPS"
		
		var count: UInt32
		var offset: UInt32 = 0xC
		
		@Count(givenBy: \Self.count)
		@Offset(givenBy: \Self.offset)
		var things: [Thing]
		
		@BinaryConvertible
		struct Thing {
			var level: UInt32
			var startingFP: UInt32
			var maxFP: UInt32
			var playerRechargePerTurn: UInt32
			var vivosaurDeathFP: UInt32
			var enemyRechargePerTurn: UInt32
		}
	}
	
	struct Unpacked {
		var things: [Thing]
		
		struct Thing: Codable {
			var level: UInt32
			var startingFP: UInt32
			var maxFP: UInt32
			var playerRechargePerTurn: UInt32
			var vivosaurDeathFP: UInt32
			var enemyRechargePerTurn: UInt32
		}
	}
}

// MARK: packed
extension KPS.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> KPS.Unpacked {
		KPS.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: KPS.Unpacked, configuration: CarbonizerConfiguration) {
		count = UInt32(unpacked.things.count)
		things = unpacked.things.map(Thing.init)
	}
}

extension KPS.Packed.Thing {
	fileprivate init(_ unpacked: KPS.Unpacked.Thing) {
		level = unpacked.level
		startingFP = unpacked.startingFP
		maxFP = unpacked.maxFP
		playerRechargePerTurn = unpacked.playerRechargePerTurn
		vivosaurDeathFP = unpacked.vivosaurDeathFP
		enemyRechargePerTurn = unpacked.enemyRechargePerTurn
	}
}

// MARK: unpacked
extension KPS.Unpacked: ProprietaryFileData {
	static let fileExtension = ".kps.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> KPS.Packed {
		KPS.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: KPS.Packed, configuration: CarbonizerConfiguration) {
		things = packed.things.map(Thing.init)
	}
}

extension KPS.Unpacked.Thing {
	fileprivate init(_ packed: KPS.Packed.Thing) {
		level = packed.level
		startingFP = packed.startingFP
		maxFP = packed.maxFP
		playerRechargePerTurn = packed.playerRechargePerTurn
		vivosaurDeathFP = packed.vivosaurDeathFP
		enemyRechargePerTurn = packed.enemyRechargePerTurn
	}
}

extension KPS.Unpacked: Codable {
	init(from decoder: any Decoder) throws {
		things = try [Thing](from: decoder)
	}
	
	func encode(to encoder: any Encoder) throws {
		try things.encode(to: encoder)
	}
}
