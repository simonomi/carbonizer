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
		var levels: [Level]
		
		@BinaryConvertible
		struct Level {
			var level: UInt32
			var startingFP: UInt32
			var maxFP: UInt32
			var playerRechargePerTurn: UInt32
			var vivosaurDeathFP: UInt32
			var enemyRechargePerTurn: UInt32
		}
	}
	
	struct Unpacked {
		var levels: [Level]
		
		struct Level: Codable {
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
		count = UInt32(unpacked.levels.count)
		levels = unpacked.levels.map(Level.init)
	}
}

extension KPS.Packed.Level {
	fileprivate init(_ unpacked: KPS.Unpacked.Level) {
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
		levels = packed.levels.map(Level.init)
	}
}

extension KPS.Unpacked.Level {
	fileprivate init(_ packed: KPS.Packed.Level) {
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
		levels = try [Level](from: decoder)
	}
	
	func encode(to encoder: any Encoder) throws {
		try levels.encode(to: encoder)
	}
}
