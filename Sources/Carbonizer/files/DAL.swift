import BinaryParser

enum DAL {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "DAL"
		var unknown1: UInt32 = 0x659
		var unknown2: UInt32 = 0x7f4
		var indicesCount: UInt32
		var indicesOffset: UInt32 = 0x14
		@Count(givenBy: \Self.indicesCount)
		@Offset(givenBy: \Self.indicesOffset)
		var indices: [UInt32]
		@Offsets(givenBy: \Self.indices)
		var attacks: [Attack]
		
		// see https://github.com/opiter09/Fossil-Fighters-Documentation/blob/main/FF1/Attack_Defs.txt
		@BinaryConvertible
		struct Attack {
			var id: UInt32
			var hitCount: UInt32
			var hitDamagesOffset: UInt32 = 0x20
			var totalDamageOffset: UInt32
			var primaryStatusDataOffset: UInt32
			var secondaryStatusDataOffset: UInt32
			var counterProof: UInt32 // 0 for counter-proof, 3 for not
			var unknown: UInt32
			
			@Count(givenBy: \Self.hitCount)
			@Offset(givenBy: \Self.hitDamagesOffset)
			var hitDamages: [Damage]
			
			@If(\Self.id, is: .notEqualTo(0))
			@Offset(givenBy: \Self.totalDamageOffset)
			var totalDamage: Damage?
			
			@If(\Self.id, is: .notEqualTo(0))
			@Offset(givenBy: \Self.primaryStatusDataOffset)
			var primaryEffect: PrimaryEffect?
			
			@If(\Self.id, is: .notEqualTo(0))
			@Offset(givenBy: \Self.secondaryStatusDataOffset)
			var secondaryEffect: SecondaryEffect?
			
			@BinaryConvertible
			struct Damage {
				var fp: UInt16
				var damage: UInt16
			}
			
			@BinaryConvertible
			struct PrimaryEffect {
				var effectCode: UInt8
				var chanceToHit: UInt8
				var turnCount: UInt8
				var icon: UInt8
				var dependsOnEffect1: UInt8
				var dependsOnEffect2: UInt8
			}
			
			@BinaryConvertible
			struct SecondaryEffect {
				var effectCode: UInt8
				var chanceToHit: UInt8
				var dependsOnEffect: UInt16
				
				var vivosaurCount: UInt32
				var vivosaursOffset: UInt32 = 0xC
				
				@Count(givenBy: \Self.vivosaurCount)
				@Offset(givenBy: \Self.vivosaursOffset)
				var vivosaurs: [UInt8] // ?
				
				@FourByteAlign
				var fourByteAlgin: ()
			}
			
			init(id: UInt32, hitCount: UInt32, totalDamageOffset: UInt32, primaryStatusDataOffset: UInt32, secondaryStatusDataOffset: UInt32, counterProof: UInt32, unknown: UInt32, hitDamages: [Damage], totalDamage: Damage?, primaryEffect: PrimaryEffect?, secondaryEffect: SecondaryEffect?) {
				self.id = id
				self.hitCount = hitCount
				self.totalDamageOffset = totalDamageOffset
				self.primaryStatusDataOffset = primaryStatusDataOffset
				self.secondaryStatusDataOffset = secondaryStatusDataOffset
				self.counterProof = counterProof
				self.unknown = unknown
				self.hitDamages = hitDamages
				self.totalDamage = totalDamage
				self.primaryEffect = primaryEffect
				self.secondaryEffect = secondaryEffect
			}
		}
	}
	
	struct Unpacked {
		var attacks: [Attack?]
		
		struct Attack: Codable {
			var id: UInt32
			var counterProof: UInt32
			var unknown: UInt32
			
			var hitDamages: [Damage]
			var totalDamage: Damage?
			var primaryEffect: PrimaryEffect?
			var secondaryEffect: SecondaryEffect?
			
			struct Damage: Codable {
				var fp: UInt16
				var damage: UInt16
			}
			
			struct PrimaryEffect: Codable {
				var effectCode: UInt8
				var chanceToHit: UInt8
				var turnCount: UInt8
				var icon: UInt8
				var dependsOnEffect1: UInt8
				var dependsOnEffect2: UInt8
			}
			
			struct SecondaryEffect: Codable {
				var effectCode: UInt8
				var chanceToHit: UInt8
				var dependsOnEffect: UInt16
				
				var vivosaurs: [UInt8]
			}
		}
	}
}

extension DAL.Packed.Attack.PrimaryEffect {
	enum Effect: UInt8 {
		case nothing = 1, poison, sleep, scare, excite, confusion, enrage, counter, enflame, harden, quicken
	}
	
	var effect: Effect {
		Effect(rawValue: effectCode) ?? .nothing
	}
}

extension DAL.Packed.Attack.SecondaryEffect {
	enum Effect: UInt8 {
		case nothing = 1, transformation, allZoneAttack, stealLPEqualToDamage, stealFP, spiteBlast, powerScale, knockToEZ, unused1, healWholeTeam, sacrifice, lawOfTheJungle, healOneAlly, unused2, cureAllStatuses, swapZones
	}
	
	var effect: Effect {
		Effect(rawValue: effectCode) ?? .nothing
	}
}

// MARK: packed
extension DAL.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> DAL.Unpacked {
		DAL.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: DAL.Unpacked, configuration: CarbonizerConfiguration) {
		attacks = unpacked.attacks.map(Attack.init)
		indicesCount = UInt32(attacks.count)
		indices = makeOffsets(
			start: indicesOffset + indicesCount * 4,
			sizes: attacks.map { $0.size() }
		)
	}
}

extension DAL.Packed.Attack {
	static let null = DAL.Packed.Attack(id: 0, hitCount: 0, totalDamageOffset: 0, primaryStatusDataOffset: 0, secondaryStatusDataOffset: 0, counterProof: 0, unknown: 0, hitDamages: [], totalDamage: nil, primaryEffect: nil, secondaryEffect: nil)
	
	fileprivate init(_ unpacked: DAL.Unpacked.Attack?) {
		guard let unpacked else {
			self = .null
			return
		}
		
		id = unpacked.id
		counterProof = unpacked.counterProof
		unknown = unpacked.unknown
		
		hitCount = UInt32(unpacked.hitDamages.count)
		hitDamages = unpacked.hitDamages.map(Damage.init)
		
		totalDamage = unpacked.totalDamage.map(Damage.init)
		primaryEffect = unpacked.primaryEffect.map(PrimaryEffect.init)
		secondaryEffect = unpacked.secondaryEffect.map(SecondaryEffect.init)
		
		if id == 0 {
			totalDamageOffset = 0
			primaryStatusDataOffset = 0
			secondaryStatusDataOffset = 0
		} else {
			totalDamageOffset = hitDamagesOffset + hitCount * 4
			primaryStatusDataOffset = totalDamageOffset + 4
			secondaryStatusDataOffset = primaryStatusDataOffset + 8
		}
	}
	
	func size() -> UInt32 {
		0x20 +
		hitCount * 4 +
		(totalDamage == nil ? 0 : 4) +
		(primaryEffect == nil ? 0 : 8) +
		(secondaryEffect?.size() ?? 0)
	}
}

extension DAL.Packed.Attack.Damage {
	fileprivate init(_ unpacked: DAL.Unpacked.Attack.Damage) {
		fp = unpacked.fp
		damage = unpacked.damage
	}
}

extension DAL.Packed.Attack.PrimaryEffect {
	fileprivate init(_ unpacked: DAL.Unpacked.Attack.PrimaryEffect) {
		effectCode = unpacked.effectCode
		chanceToHit = unpacked.chanceToHit
		turnCount = unpacked.turnCount
		icon = unpacked.icon
		dependsOnEffect1 = unpacked.dependsOnEffect1
		dependsOnEffect2 = unpacked.dependsOnEffect2
	}
}

extension DAL.Packed.Attack.SecondaryEffect {
	fileprivate init(_ unpacked: DAL.Unpacked.Attack.SecondaryEffect) {
		effectCode = unpacked.effectCode
		chanceToHit = unpacked.chanceToHit
		dependsOnEffect = unpacked.dependsOnEffect
		
		vivosaurCount = UInt32(unpacked.vivosaurs.count)
		vivosaurs = unpacked.vivosaurs
	}
	
	func size() -> UInt32 {
		0xC + vivosaurCount.roundedUpToTheNearest(4)
	}
}

// MARK: unpacked
extension DAL.Unpacked: ProprietaryFileData {
	static let fileExtension = ".dal.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> DAL.Packed {
		DAL.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: DAL.Packed, configuration: CarbonizerConfiguration) {
		attacks = packed.attacks.map(Attack.init)
	}
}

extension DAL.Unpacked.Attack {
	fileprivate init?(_ packed: DAL.Packed.Attack) {
		if packed.id == 0 { return nil }
		
		id = packed.id
		counterProof = packed.counterProof
		unknown = packed.unknown
		
		hitDamages = packed.hitDamages.map(Damage.init)
		totalDamage = packed.totalDamage.map(Damage.init)
		primaryEffect = packed.primaryEffect.map(PrimaryEffect.init)
		secondaryEffect = packed.secondaryEffect.map(SecondaryEffect.init)
	}
}

extension DAL.Unpacked.Attack.Damage {
	fileprivate init(_ packed: DAL.Packed.Attack.Damage) {
		fp = packed.fp
		damage = packed.damage
	}
}

extension DAL.Unpacked.Attack.PrimaryEffect {
	fileprivate init(_ packed: DAL.Packed.Attack.PrimaryEffect) {
		effectCode = packed.effectCode
		chanceToHit = packed.chanceToHit
		turnCount = packed.turnCount
		icon = packed.icon
		dependsOnEffect1 = packed.dependsOnEffect1
		dependsOnEffect2 = packed.dependsOnEffect2
	}
}

extension DAL.Unpacked.Attack.SecondaryEffect {
	fileprivate init(_ packed: DAL.Packed.Attack.SecondaryEffect) {
		effectCode = packed.effectCode
		chanceToHit = packed.chanceToHit
		dependsOnEffect = packed.dependsOnEffect
		
		vivosaurs = packed.vivosaurs
	}
}

extension DAL.Unpacked: Codable {
	init(from decoder: any Decoder) throws {
		attacks = try [Attack?](from: decoder)
	}
	
	func encode(to encoder: any Encoder) throws {
		try attacks.encode(to: encoder)
	}
}
