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
			var unknown: UInt32 // always 0 or 3
								// AOE?
			
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
				var effect: Effect
				var chanceToHit: UInt8
				var turnCount: UInt8
				var icon: UInt8
				var effectArgument1: UInt8
				var effectArgument2: UInt8
				
				enum Effect: UInt8 {
					case nothing = 1, poison, sleep, scare, excite, confusion, enrage, counter, enflame, harden, quicken
				}
			}
			
			@BinaryConvertible
			struct SecondaryEffect {
				var effect: Effect
				var chanceToHit: UInt8
				var effectArgument: UInt16
				
				var transformVivosaurCount: UInt32
				var transformVivosaurIDsOffset: UInt32 = 0xC
				
				@Count(givenBy: \Self.transformVivosaurCount)
				@Offset(givenBy: \Self.transformVivosaurIDsOffset)
				var transformVivosaurIDs: [UInt8]
				
				@FourByteAlign
				var fourByteAlgin: ()
				
				enum Effect: UInt8 {
					case nothing = 1, transformation, allZoneAttack, stealLPEqualToDamage, stealFP, spiteBlast, powerScale, knockToEZ, unused1, healWholeTeam, sacrifice, lawOfTheJungle, healOneAlly, unused2, cureAllStatuses, swapZones
				}
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
				var effect: Effect
				var chanceToHit: UInt8
				var turnCount: UInt8
				var icon: UInt8 // normal poison 02, gold 03, sleep 04, gold 05...
				
				enum Effect: Codable {
					case nothing(unknown: UInt8) // argument is always 1
					case poison(damagePercent: UInt8)
					case sleep
					case scare(movesAffected: UInt8)
					case excite
					case confusion
					case enrage(attackRaised: UInt8, accuracyLowered: UInt8)
					case counter(chance: UInt8)
					case enflame(attackRaised: UInt8, defenseLowered: UInt8)
					case harden(defenseRaised: UInt8)
					case quicken(evasionRaised: UInt8)
				}
			}
			
			struct SecondaryEffect: Codable {
				var effect: Effect
				var chanceToHit: UInt8
				
				enum Effect: Codable {
					case nothing
					case transformation(unknown: UInt16, vivosaurs: [Vivosaur]) // argument is always 1
					case allZoneAttack
					case stealLPEqualToDamage
					case stealFP(amount: UInt16)
					case spiteBlast(damage: UInt16)
					case powerScale
					case knockToEZ
					case unused1(healingAmount: UInt16) // heal only self?
					case healWholeTeam(healingAmount: UInt16)
					case sacrifice
					case lawOfTheJungle
					case healOneAlly(healingAmount: UInt16)
					case unused2(healingAmount: UInt16) // heal only other ally?
					case cureAllStatuses
					case swapZones
					
					struct Vivosaur: Codable {
						var id: UInt8
						var _name: String?
						
						init(id: UInt8) {
							self.id = id
						}
					}
				}
			}
		}
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
		effect = Effect(unpacked.effect)
		chanceToHit = unpacked.chanceToHit
		turnCount = unpacked.turnCount
		icon = unpacked.icon
		effectArgument1 = unpacked.effect.argument1
		effectArgument2 = unpacked.effect.argument2
	}
}

extension DAL.Packed.Attack.PrimaryEffect.Effect {
	fileprivate init(_ unpacked: DAL.Unpacked.Attack.PrimaryEffect.Effect) {
		self = switch unpacked {
			case .nothing: .nothing
			case .poison: .poison
			case .sleep: .sleep
			case .scare: .scare
			case .excite: .excite
			case .confusion: .confusion
			case .enrage: .enrage
			case .counter: .counter
			case .enflame: .enflame
			case .harden: .harden
			case .quicken: .quicken
		}
	}
}

extension DAL.Unpacked.Attack.PrimaryEffect.Effect {
	var argument1: UInt8 {
		switch self {
			case .nothing(let argument),
				 .poison(let argument),
				 .scare(let argument),
				 .enrage(let argument, _),
				 .counter(let argument),
				 .enflame(let argument, _),
				 .harden(let argument),
				 .quicken(let argument):
				argument
			case .sleep, .excite, .confusion: 0
		}
	}
	
	var argument2: UInt8 {
		switch self {
			case .enrage(_, let argument),
				 .enflame(_, let argument):
				argument
			case .nothing, .poison, .sleep, .scare, .excite, .confusion, .counter, .harden, .quicken: 0
		}
	}
}

extension DAL.Packed.Attack.PrimaryEffect.Effect: BinaryConvertible {
	struct InvalidPrimaryEffectID: Error, CustomStringConvertible {
		var id: UInt8
		
		var description: String {
			"invalid effect ID for primary effect: \(.red)\(id)\(.normal), expected \(.green)1–11\(.red)"
		}
	}
	
	init(_ data: Datastream) throws {
		let raw = try data.read(UInt8.self)
		guard let effect = Self(rawValue: raw) else {
			throw InvalidPrimaryEffectID(id: raw)
		}
		self = effect
	}
	
	func write(to data: Datawriter) {
		data.write(rawValue)
	}
}

extension DAL.Packed.Attack.SecondaryEffect {
	fileprivate init(_ unpacked: DAL.Unpacked.Attack.SecondaryEffect) {
		effect = Effect(unpacked.effect)
		chanceToHit = unpacked.chanceToHit
		effectArgument = unpacked.effect.argument
		
		transformVivosaurIDs = unpacked.effect.transformVivosaurs ?? []
		transformVivosaurCount = UInt32(transformVivosaurIDs.count)
	}
	
	func size() -> UInt32 {
		0xC + transformVivosaurCount.roundedUpToTheNearest(4)
	}
}

extension DAL.Unpacked.Attack.SecondaryEffect.Effect {
	var transformVivosaurs: [UInt8]? {
		if case .transformation(_, let vivosaurs) = self {
			vivosaurs.map(\.id)
		} else {
			nil
		}
	}
}

extension DAL.Packed.Attack.SecondaryEffect.Effect {
	fileprivate init(_ unpacked: DAL.Unpacked.Attack.SecondaryEffect.Effect) {
		self = switch unpacked {
			case .nothing: .nothing
			case .transformation: .transformation
			case .allZoneAttack: .allZoneAttack
			case .stealLPEqualToDamage: .stealLPEqualToDamage
			case .stealFP: .stealFP
			case .spiteBlast: .spiteBlast
			case .powerScale: .powerScale
			case .knockToEZ: .knockToEZ
			case .unused1: .unused1
			case .healWholeTeam: .healWholeTeam
			case .sacrifice: .sacrifice
			case .lawOfTheJungle: .lawOfTheJungle
			case .healOneAlly: .healOneAlly
			case .unused2: .unused2
			case .cureAllStatuses: .cureAllStatuses
			case .swapZones: .swapZones
		}
	}
}

extension DAL.Unpacked.Attack.SecondaryEffect.Effect {
	var argument: UInt16 {
		switch self {
			case .transformation(let argument, _),
				 .stealFP(let argument),
				 .spiteBlast(let argument),
				 .unused1(let argument),
				 .healWholeTeam(let argument),
				 .healOneAlly(let argument),
				 .unused2(let argument):
				argument
			case .nothing, .allZoneAttack, .stealLPEqualToDamage, .powerScale, .knockToEZ, .sacrifice, .lawOfTheJungle, .cureAllStatuses, .swapZones: 0
		}
	}
}

extension DAL.Packed.Attack.SecondaryEffect.Effect: BinaryConvertible {
	struct InvalidSecondaryEffectID: Error, CustomStringConvertible {
		var id: UInt8
		
		var description: String {
			"invalid effect ID for secondary effect: \(.red)\(id)\(.normal), expected \(.green)1–16\(.red)"
		}
	}
	
	init(_ data: Datastream) throws {
		let raw = try data.read(UInt8.self)
		guard let effect = Self(rawValue: raw) else {
			throw InvalidSecondaryEffectID(id: raw)
		}
		self = effect
	}
	
	func write(to data: Datawriter) {
		data.write(rawValue)
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
		effect = Effect(packed.effect, arguments: packed.effectArgument1, packed.effectArgument2)
		chanceToHit = packed.chanceToHit
		turnCount = packed.turnCount
		icon = packed.icon
	}
}

extension DAL.Unpacked.Attack.PrimaryEffect.Effect {
	fileprivate init(
		_ packed: DAL.Packed.Attack.PrimaryEffect.Effect,
		arguments argument1: UInt8,
		_ argument2: UInt8
	) {
		self = switch packed {
			case .nothing: .nothing(unknown: argument1)
			case .poison: .poison(damagePercent: argument1)
			case .sleep: .sleep
			case .scare: .scare(movesAffected: argument1)
			case .excite: .excite
			case .confusion: .confusion
			case .enrage: .enrage(attackRaised: argument1, accuracyLowered: argument2)
			case .counter: .counter(chance: argument1)
			case .enflame: .enflame(attackRaised: argument1, defenseLowered: argument2)
			case .harden: .harden(defenseRaised: argument1)
			case .quicken: .quicken(evasionRaised: argument1)
		}
	}
}

extension DAL.Unpacked.Attack.SecondaryEffect {
	fileprivate init(_ packed: DAL.Packed.Attack.SecondaryEffect) {
		effect = Effect(packed.effect, arguments: packed.effectArgument, packed.transformVivosaurIDs)
		chanceToHit = packed.chanceToHit
	}
}

extension DAL.Unpacked.Attack.SecondaryEffect.Effect {
	fileprivate init(
		_ packed: DAL.Packed.Attack.SecondaryEffect.Effect,
		arguments argument: UInt16,
		_ transformVivosaurIDs: [UInt8]
	) {
		self = switch packed {
			case .nothing: .nothing
			case .transformation: .transformation(unknown: argument, vivosaurs: transformVivosaurIDs.map(Vivosaur.init))
			case .allZoneAttack: .allZoneAttack
			case .stealLPEqualToDamage: .stealLPEqualToDamage
			case .stealFP: .stealFP(amount: argument)
			case .spiteBlast: .spiteBlast(damage: argument)
			case .powerScale: .powerScale
			case .knockToEZ: .knockToEZ
			case .unused1: .unused1(healingAmount: argument)
			case .healWholeTeam: .healWholeTeam(healingAmount: argument)
			case .sacrifice: .sacrifice
			case .lawOfTheJungle: .lawOfTheJungle
			case .healOneAlly: .healOneAlly(healingAmount: argument)
			case .unused2: .unused2(healingAmount: argument)
			case .cureAllStatuses: .cureAllStatuses
			case .swapZones: .swapZones
		}
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
