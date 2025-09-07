import BinaryParser

enum DCL {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "DCL"
		
		var unknown1: UInt32
		var unknown2: UInt32
		var unknown3: UInt32
		var unknown4: UInt32
		
		var vivosaurCount: UInt32
		var indicesOffset: UInt32 = 0x2C
		
		var unknown5: UInt32
		var unknown6: UInt32
		var unknown7: UInt32
		var unknown8: UInt32
		
		@Count(givenBy: \Self.vivosaurCount)
		@Offset(givenBy: \Self.indicesOffset)
		var indices: [UInt32]
		
		@Offsets(givenBy: \Self.indices)
		var vivosaurs: [Vivosaur]
		
		// see https://github.com/opiter09/Fossil-Fighters-Documentation/blob/main/FF1/Creature_Defs.txt
		@BinaryConvertible
		struct Vivosaur {
			var id: Int32
			
			var unknown1: UInt32 = 0
			var unknown2: UInt32 = 0
			
			var length: UInt8
			var element: Element?
			var rank12HealthDividedBy2: UInt16
			
			var attack: Stat
			var defense: Stat
			var accuracy: Stat
			var evasion: Stat
			
			var crit: UInt8
			var critAgain: UInt8 // always the same as crit
			
			var linkChance: UInt8
			
			var unknown3: UInt8 // always 100
			
			var teams: Teams
			
			var moveCount: UInt32 // always 3 or 4
			var skillIdsOffset: UInt32 = 0x8c
			
			var teamSkill: UInt32
			var linkSkill: UInt32
			
			var long1234Count: UInt32 // always the same as moveCount
			var long1234Offset: UInt32
			
			var unknown4: UInt32 // always 1
			var unknown5: UInt32 = 0
			var unknown6: UInt32 = 0
			var unknown7: UInt32 = 0
			var unknown8: UInt32 = 0
			
			var allySupportEffectsOffset: UInt32
			var enemySupportEffectsOffset: UInt32
			
			var unknown9: UInt8 // always 1
			var unknown10: UInt8 // always 1
			var unknown11: UInt8 // always 100
			var unknown12: UInt8 // always 100
			
			var unknown13: UInt8 // always 100
			
			var passiveAbility: PassiveAbility
			
			@Padding(bytes: 1)
			
			var statusChancesCount: UInt32 // always 10
			var statusChancesOffset: UInt32
			
			var szDamageMultiplier: UInt32
			
			var unknown16: UInt32 // always 40
			
			var moveCountAgainAgain: UInt32 // always the same as moveCount
			var moveListOrderOffset: UInt32
			
			var rankCount: UInt32 // always 12
			var healthAtEachRankOffset: UInt32
			
			var displayNumber: UInt32 // only different than id for OP Frigi and OP Igno
			var alphabeticalOrder: UInt32
			
			@Count(givenBy: \Self.moveCount)
			@Offset(givenBy: \Self.skillIdsOffset)
			var skillIds: [UInt32]
			
			// what fossil you learn the move at (123/1234 for normal, 1111 for chickens)
			@Count(givenBy: \Self.long1234Count)
			@Offset(givenBy: \Self.long1234Offset)
			var long1234: [UInt32]
			
			@Offset(givenBy: \Self.allySupportEffectsOffset)
			var allySupportEffects: SupportEffects
			@Offset(givenBy: \Self.enemySupportEffectsOffset)
			var enemySupportEffects: SupportEffects
			
			// chances to receive poison, sleep, scare, excite, confusion, enrage, counter, enflame, harden, and quicken respectively
			@Count(givenBy: \Self.statusChancesCount)
			@Offset(givenBy: \Self.statusChancesOffset)
			var statusChances: [UInt8]
			
			@Count(givenBy: \Self.moveCountAgainAgain)
			@Offset(givenBy: \Self.moveListOrderOffset)
			var moveListOrder: [UInt8] // always 123 or 1234
			
			@Count(givenBy: \Self.rankCount)
			@Offset(givenBy: \Self.healthAtEachRankOffset)
			var healthAtEachRank: [UInt16]
			
			enum Element: UInt8 {
				case fire = 1, air, earth, water, neutral, legendary
			}
			
			@BinaryConvertible
			struct Stat {
				var growthRate: UInt8
				var rank8Value: UInt8
				var rank1Value: UInt8
				var rank12Value: UInt8
			}
			
			@BinaryConvertible
			struct Teams: OptionSet {
				let rawValue: UInt32 // only the first 16 bits are used in FF1
				
				static let fireType    = Self(rawValue: 1 << 0)
				static let airType     = Self(rawValue: 1 << 1)
				static let earthType   = Self(rawValue: 1 << 2)
				static let waterType   = Self(rawValue: 1 << 3)
				static let neutralType = Self(rawValue: 1 << 4)
				static let violent     = Self(rawValue: 1 << 5)
				static let group7      = Self(rawValue: 1 << 6)
				static let group8      = Self(rawValue: 1 << 7)
				static let group9      = Self(rawValue: 1 << 8)
				static let group10     = Self(rawValue: 1 << 9)
				static let group11     = Self(rawValue: 1 << 10)
				static let group12     = Self(rawValue: 1 << 11)
				static let group13     = Self(rawValue: 1 << 12)
				static let group14     = Self(rawValue: 1 << 13)
				static let group15     = Self(rawValue: 1 << 14)
				static let japanese    = Self(rawValue: 1 << 15)
			}
			
			enum PassiveAbility: BinaryConvertible {
				case none // ideally this would be an optional, but we're already using up
						  // `Optional`'s conformance to `BinaryConvertible` for `Element?`
				case nothing
				case fpPlus(UInt8) // (+percent + 100) / 10
				case partingBlow(UInt8) // percent / 10
				case autoLPRecovery(UInt8) // percent
				case autoCounter
				case statusEffectsDisabled
				
				enum InvalidDataError: Error {
					case invalidType(UInt8)
					case invalidArgument(UInt8, type: UInt8)
					
					// TODO: custom description
				}
				
				init(_ data: Datastream) throws {
					let type = try data.read(UInt8.self)
					let argument = try data.read(UInt8.self)
					
					if type == 0, argument == 0 {
						self = .none
						return
					}
					
					switch type {
						case 1: 
							guard argument == 0 else {
								throw InvalidDataError.invalidArgument(argument, type: type)
							}
							self = .nothing
						case 4:
							self = .fpPlus(argument)
						case 5:
							self = .partingBlow(argument)
						case 6:
							self = .autoLPRecovery(argument)
						case 7:
							guard argument == 100 else {
								throw InvalidDataError.invalidArgument(argument, type: type)
							}
							self = .autoCounter
						case 8:
							guard argument == 1 else {
								throw InvalidDataError.invalidArgument(argument, type: type)
							}
							self = .statusEffectsDisabled
						default:
							throw InvalidDataError.invalidType(type)
					}
				}
				
				func write(to data: Datawriter) {
					switch self {
						case .none:
							data.write(UInt8(0))
							data.write(UInt8(0))
						case .nothing:
							data.write(UInt8(1))
							data.write(UInt8(0))
						case .fpPlus(let argument):
							data.write(UInt8(4))
							data.write(argument)
						case .partingBlow(let argument):
							data.write(UInt8(5))
							data.write(argument)
						case .autoLPRecovery(let argument):
							data.write(UInt8(6))
							data.write(argument)
						case .autoCounter:
							data.write(UInt8(7))
							data.write(UInt8(100))
						case .statusEffectsDisabled:
							data.write(UInt8(8))
							data.write(UInt8(1))
					}
				}
			}
			
			@BinaryConvertible
			struct SupportEffects {
				var attack: Int8
				var defense: Int8
				var accuracy: Int8
				var evasion: Int8
			}
			
			init(id: Int32, unknown1: UInt32, unknown2: UInt32, length: UInt8, element: Element? = nil, rank12HealthDividedBy2: UInt16, attack: Stat, defense: Stat, accuracy: Stat, evasion: Stat, crit: UInt8, critAgain: UInt8, linkChance: UInt8, unknown3: UInt8, teams: Teams, moveCount: UInt32, skillIdsOffset: UInt32, teamSkill: UInt32, linkSkill: UInt32, long1234Count: UInt32, long1234Offset: UInt32, unknown4: UInt32, unknown5: UInt32, unknown6: UInt32, unknown7: UInt32, unknown8: UInt32, allySupportEffectsOffset: UInt32, enemySupportEffectsOffset: UInt32, unknown9: UInt8, unknown10: UInt8, unknown11: UInt8, unknown12: UInt8, unknown13: UInt8, passiveAbility: PassiveAbility, statusChancesCount: UInt32, statusChancesOffset: UInt32, szDamageMultiplier: UInt32, unknown16: UInt32, moveCountAgainAgain: UInt32, moveListOrderOffset: UInt32, rankCount: UInt32, healthAtEachRankOffset: UInt32, displayNumber: UInt32, alphabeticalOrder: UInt32, skillIds: [UInt32], long1234: [UInt32], allySupportEffects: SupportEffects, enemySupportEffects: SupportEffects, statusChances: [UInt8], moveListOrder: [UInt8], padding: UInt8? = nil, healthAtEachRank: [UInt16]) {
				self.id = id
				self.unknown1 = unknown1
				self.unknown2 = unknown2
				self.length = length
				self.element = element
				self.rank12HealthDividedBy2 = rank12HealthDividedBy2
				self.attack = attack
				self.defense = defense
				self.accuracy = accuracy
				self.evasion = evasion
				self.crit = crit
				self.critAgain = critAgain
				self.linkChance = linkChance
				self.unknown3 = unknown3
				self.teams = teams
				self.moveCount = moveCount
				self.skillIdsOffset = skillIdsOffset
				self.teamSkill = teamSkill
				self.linkSkill = linkSkill
				self.long1234Count = long1234Count
				self.long1234Offset = long1234Offset
				self.unknown4 = unknown4
				self.unknown5 = unknown5
				self.unknown6 = unknown6
				self.unknown7 = unknown7
				self.unknown8 = unknown8
				self.allySupportEffectsOffset = allySupportEffectsOffset
				self.enemySupportEffectsOffset = enemySupportEffectsOffset
				self.unknown9 = unknown9
				self.unknown10 = unknown10
				self.unknown11 = unknown11
				self.unknown12 = unknown12
				self.unknown13 = unknown13
				self.passiveAbility = passiveAbility
				self.statusChancesCount = statusChancesCount
				self.statusChancesOffset = statusChancesOffset
				self.szDamageMultiplier = szDamageMultiplier
				self.unknown16 = unknown16
				self.moveCountAgainAgain = moveCountAgainAgain
				self.moveListOrderOffset = moveListOrderOffset
				self.rankCount = rankCount
				self.healthAtEachRankOffset = healthAtEachRankOffset
				self.displayNumber = displayNumber
				self.alphabeticalOrder = alphabeticalOrder
				self.skillIds = skillIds
				self.long1234 = long1234
				self.allySupportEffects = allySupportEffects
				self.enemySupportEffects = enemySupportEffects
				self.statusChances = statusChances
				self.moveListOrder = moveListOrder
				self.healthAtEachRank = healthAtEachRank
			}
		}
	}
	
	struct Unpacked: Codable {
		var unknown1: UInt32
		var unknown2: UInt32
		var unknown3: UInt32
		var unknown4: UInt32
		var unknown5: UInt32
		var unknown6: UInt32
		var unknown7: UInt32
		var unknown8: UInt32
		
		var vivosaurs: [Vivosaur?]
		
		struct Vivosaur: Codable {
			var _label: String?
			
			var id: Int32
			
			var length: UInt8
			var element: Element?
			var rank12HealthDividedBy2: UInt16
			
			var attack: Stat
			var defense: Stat
			var accuracy: Stat
			var evasion: Stat
			
			var crit: UInt8
			var critAgain: UInt8
			
			var linkChance: UInt8
			
			var unknown3: UInt8
			
			var teams: [Team]
			
			var teamSkill: UInt32
			var linkSkill: UInt32
			
			var unknown4: UInt32
			
			var unknown9: UInt8
			var unknown10: UInt8
			var unknown11: UInt8
			var unknown12: UInt8
			
			var unknown13: UInt8
			
			var passiveAbility: PassiveAbility?
			
			var szDamageMultiplier: UInt32
			
			var unknown16: UInt32
			
			var displayNumber: UInt32
			var alphabeticalOrder: UInt32
			
			var skillIds: [UInt32]
			
			// what fossil you learn the move at (123/1234 for normal, 1111 for chickens)
			var long1234: [UInt32]
			
			var allySupportEffects: SupportEffects
			var enemySupportEffects: SupportEffects
			
			// chances to receive poison, sleep, scare, excite, confusion, enrage, counter, enflame, harden, and quicken respectively
			var statusChances: [UInt8]
			
			var moveListOrder: [UInt8]
			
			var healthAtEachRank: [UInt16]
			
			enum Element: String {
				case fire, air, earth, water, neutral, legendary
			}
			
			struct Stat: Codable {
				var growthRate: UInt8
				var rank8Value: UInt8
				var rank1Value: UInt8
				var rank12Value: UInt8
			}
			
			enum Team: String, Codable, CaseIterable {
				case fireType, airType, earthType, waterType, neutralType, violent, group7, group8, group9, group10, group11, group12, group13, group14, group15, japanese
			}
			
			enum PassiveAbility {
				case nothing
				case fpPlus(UInt8) // (+percent + 100) / 10
				case partingBlow(UInt8) // percent / 10
				case autoLPRecovery(UInt8) // percent
				case autoCounter
				case statusEffectsDisabled
			}
			
			struct SupportEffects: Codable {
				var attack: Int8
				var defense: Int8
				var accuracy: Int8
				var evasion: Int8
			}
		}
	}
}

extension DCL.Packed.Vivosaur.Element?: BinaryConvertible {
	struct InvalidElement: Error {
		var raw: UInt8
		
		// TODO: custom description
	}
	
	public init(_ data: Datastream) throws {
		let rawByte = try data.read(UInt8.self)
		
		guard rawByte != 0 else {
			self = nil
			return
		}
		
		guard let element = DCL.Packed.Vivosaur.Element(rawValue: rawByte) else {
			throw InvalidElement(raw: rawByte)
		}
		
		self = element
	}
	
	public func write(to data: Datawriter) {
		if let rawValue = self?.rawValue {
			data.write(rawValue)
		} else {
			data.write(UInt8.zero)
		}
	}
}

// MARK: packed
extension DCL.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> DCL.Unpacked {
		DCL.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: DCL.Unpacked, configuration: CarbonizerConfiguration) {
		unknown1 = unpacked.unknown1
		unknown2 = unpacked.unknown2
		unknown3 = unpacked.unknown3
		unknown4 = unpacked.unknown4
		unknown5 = unpacked.unknown5
		unknown6 = unpacked.unknown6
		unknown7 = unpacked.unknown7
		unknown8 = unpacked.unknown8
		
		vivosaurCount = UInt32(unpacked.vivosaurs.count)
		
		vivosaurs = unpacked.vivosaurs.map {
			$0.map(Vivosaur.init) ?? .null
		}
		
		indices = makeOffsets(
			start: indicesOffset + 4 * vivosaurCount,
			sizes: vivosaurs.map { $0.size() }
		)
	}
}

extension DCL.Packed.Vivosaur {
	static let null = Self(id: 0, unknown1: 0, unknown2: 0, length: 0, rank12HealthDividedBy2: 0, attack: .null, defense: .null, accuracy: .null, evasion: .null, crit: 0, critAgain: 0, linkChance: 0, unknown3: 0, teams: Teams(rawValue: 0), moveCount: 0, skillIdsOffset: 0x8c, teamSkill: 0, linkSkill: 0, long1234Count: 0, long1234Offset: 0x8c, unknown4: 0, unknown5: 0, unknown6: 0, unknown7: 0, unknown8: 0, allySupportEffectsOffset: 0, enemySupportEffectsOffset: 0, unknown9: 0, unknown10: 0, unknown11: 0, unknown12: 0, unknown13: 0, passiveAbility: .none, statusChancesCount: 0, statusChancesOffset: 0x8c, szDamageMultiplier: 0, unknown16: 0, moveCountAgainAgain: 0, moveListOrderOffset: 0x8C, rankCount: 0, healthAtEachRankOffset: 0x8c, displayNumber: 0, alphabeticalOrder: 0, skillIds: [], long1234: [], allySupportEffects: .null, enemySupportEffects: .null, statusChances: [], moveListOrder: [], healthAtEachRank: [])
	
	fileprivate init(_ unpacked: DCL.Unpacked.Vivosaur) {
		id = unpacked.id
		
		length = unpacked.length
		element = unpacked.element.map(Element.init)
		rank12HealthDividedBy2 = unpacked.rank12HealthDividedBy2
		
		attack = Stat(unpacked.attack)
		defense = Stat(unpacked.defense)
		accuracy = Stat(unpacked.accuracy)
		evasion = Stat(unpacked.evasion)
		
		crit = unpacked.crit
		critAgain = unpacked.critAgain
		
		linkChance = unpacked.linkChance
		
		unknown3 = unpacked.unknown3
		
		teams = unpacked.teams
			.map(Teams.init)
			.reduce([]) { $0.union($1) }
		
		moveCount = UInt32(unpacked.skillIds.count)
		
		teamSkill = unpacked.teamSkill
		linkSkill = unpacked.linkSkill
		
		long1234Count = UInt32(unpacked.long1234.count)
		long1234Offset = skillIdsOffset + moveCount * 4
		
		unknown4 = unpacked.unknown4
		
		allySupportEffectsOffset = long1234Offset + long1234Count * 4
		enemySupportEffectsOffset = allySupportEffectsOffset + 4
		
		unknown9 = unpacked.unknown9
		unknown10 = unpacked.unknown10
		unknown11 = unpacked.unknown11
		unknown12 = unpacked.unknown12
		
		unknown13 = unpacked.unknown13
		
		passiveAbility = PassiveAbility(unpacked.passiveAbility)
		
		statusChancesCount = UInt32(unpacked.statusChances.count)
		statusChancesOffset = enemySupportEffectsOffset + 4
		
		szDamageMultiplier = unpacked.szDamageMultiplier
		
		unknown16 = unpacked.unknown16
		
		moveCountAgainAgain = UInt32(unpacked.moveListOrder.count)
		moveListOrderOffset = statusChancesOffset + statusChancesCount.roundedUpToTheNearest(4)
		
		rankCount = UInt32(unpacked.healthAtEachRank.count)
		healthAtEachRankOffset = moveListOrderOffset + moveCountAgainAgain.roundedUpToTheNearest(4)
		
		displayNumber = unpacked.displayNumber
		alphabeticalOrder = unpacked.alphabeticalOrder
		
		skillIds = unpacked.skillIds
		
		long1234 = unpacked.long1234
		
		allySupportEffects = SupportEffects(unpacked.allySupportEffects)
		enemySupportEffects = SupportEffects(unpacked.enemySupportEffects)
		
		statusChances = unpacked.statusChances
		
		moveListOrder = unpacked.moveListOrder
		
		healthAtEachRank = unpacked.healthAtEachRank
	}
	
	func size() -> UInt32 {
		0x8C +
		(moveCount * 4) +
		(long1234Count * 4) +
		(id == 0 ? 0 : 8) + // support effects
		statusChancesCount.roundedUpToTheNearest(4) +
		moveCountAgainAgain.roundedUpToTheNearest(4) +
		(rankCount * 2)
	}
}

extension DCL.Packed.Vivosaur.Element {
	fileprivate init(_ unpacked: DCL.Unpacked.Vivosaur.Element) {
		self = switch unpacked {
			case .fire: .fire
			case .air: .air
			case .earth: .earth
			case .water: .water
			case .neutral: .neutral
			case .legendary: .legendary
		}
	}
}

extension DCL.Packed.Vivosaur.Stat {
	static let null = Self(growthRate: 0, rank8Value: 0, rank1Value: 0, rank12Value: 0)
	
	fileprivate init(_ unpacked: DCL.Unpacked.Vivosaur.Stat) {
		growthRate = unpacked.growthRate
		rank8Value = unpacked.rank8Value
		rank1Value = unpacked.rank1Value
		rank12Value = unpacked.rank12Value
	}
}

extension DCL.Packed.Vivosaur.Teams {
	fileprivate init(_ unpacked: DCL.Unpacked.Vivosaur.Team) {
		self = switch unpacked {
			case .fireType: .fireType
			case .airType: .airType
			case .earthType: .earthType
			case .waterType: .waterType
			case .neutralType: .neutralType
			case .violent: .violent
			case .group7: .group7
			case .group8: .group8
			case .group9: .group9
			case .group10: .group10
			case .group11: .group11
			case .group12: .group12
			case .group13: .group13
			case .group14: .group14
			case .group15: .group15
			case .japanese: .japanese
		}
	}
}

extension DCL.Packed.Vivosaur.PassiveAbility {
	fileprivate init(_ unpacked: DCL.Unpacked.Vivosaur.PassiveAbility?) {
		self = switch unpacked {
			case nil: .none
			case .nothing: .nothing
			case .fpPlus(let int): .fpPlus(int)
			case .partingBlow(let int): .partingBlow(int)
			case .autoLPRecovery(let int): .autoLPRecovery(int)
			case .autoCounter: .autoCounter
			case .statusEffectsDisabled: .statusEffectsDisabled
		}
	}
}

extension DCL.Packed.Vivosaur.SupportEffects {
	static let null = Self(attack: 0, defense: 0, accuracy: 0, evasion: 0)
	
	fileprivate init(_ unpacked: DCL.Unpacked.Vivosaur.SupportEffects) {
		attack = unpacked.attack
		defense = unpacked.defense
		accuracy = unpacked.accuracy
		evasion = unpacked.evasion
	}
}

// MARK: unpacked
extension DCL.Unpacked: ProprietaryFileData {
	static let fileExtension = ".dcl.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> DCL.Packed {
		DCL.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: DCL.Packed, configuration: CarbonizerConfiguration) {
		unknown1 = packed.unknown1
		unknown2 = packed.unknown2
		unknown3 = packed.unknown3
		unknown4 = packed.unknown4
		unknown5 = packed.unknown5
		unknown6 = packed.unknown6
		unknown7 = packed.unknown7
		unknown8 = packed.unknown8
		
		vivosaurs = packed.vivosaurs.map(Vivosaur.init)
	}
}

extension DCL.Unpacked.Vivosaur {
	init?(_ packed: DCL.Packed.Vivosaur) {
		guard packed.id != 0 else { return nil }
		
		_label = vivosaurNames[packed.id]
		
		id = packed.id
		
		length = packed.length
		element = packed.element.map(Element.init)
		rank12HealthDividedBy2 = packed.rank12HealthDividedBy2
		
		attack = Stat(packed.attack)
		defense = Stat(packed.defense)
		accuracy = Stat(packed.accuracy)
		evasion = Stat(packed.evasion)
		
		crit = packed.crit
		critAgain = packed.critAgain
		
		linkChance = packed.linkChance
		
		unknown3 = packed.unknown3
		
		teams = [Team](packed.teams)
		
		teamSkill = packed.teamSkill
		linkSkill = packed.linkSkill
		
		unknown4 = packed.unknown4
		
		unknown9 = packed.unknown9
		unknown10 = packed.unknown10
		unknown11 = packed.unknown11
		unknown12 = packed.unknown12
		
		unknown13 = packed.unknown13
		
		passiveAbility = PassiveAbility?(packed.passiveAbility)
		
		szDamageMultiplier = packed.szDamageMultiplier
		
		unknown16 = packed.unknown16
		
		displayNumber = packed.displayNumber
		alphabeticalOrder = packed.alphabeticalOrder
		
		skillIds = packed.skillIds
		
		long1234 = packed.long1234
		
		allySupportEffects = SupportEffects(packed.allySupportEffects)
		enemySupportEffects = SupportEffects(packed.enemySupportEffects)
		
		statusChances = packed.statusChances
		
		moveListOrder = packed.moveListOrder
		
		healthAtEachRank = packed.healthAtEachRank
	}
}

extension DCL.Unpacked.Vivosaur.Element: Codable {
	init(_ packed: DCL.Packed.Vivosaur.Element) {
		self = switch packed {
			case .fire: .fire
			case .air: .air
			case .earth: .earth
			case .water: .water
			case .neutral: .neutral
			case .legendary: .legendary
		}
	}
}

extension DCL.Unpacked.Vivosaur.Stat {
	init(_ packed: DCL.Packed.Vivosaur.Stat) {
		growthRate = packed.growthRate
		rank8Value = packed.rank8Value
		rank1Value = packed.rank1Value
		rank12Value = packed.rank12Value
	}
}

extension [DCL.Unpacked.Vivosaur.Team] {
	init(_ packed: DCL.Packed.Vivosaur.Teams) {
		self = DCL.Unpacked.Vivosaur.Team.allCases
			.filter { packed.contains(DCL.Packed.Vivosaur.Teams($0)) }
	}
}

extension DCL.Unpacked.Vivosaur.PassiveAbility? {
	init(_ packed: DCL.Packed.Vivosaur.PassiveAbility) {
		self = switch packed {
			case .none: nil
			case .nothing: .nothing
			case .fpPlus(let uInt8): .fpPlus(uInt8)
			case .partingBlow(let uInt8): .partingBlow(uInt8)
			case .autoLPRecovery(let uInt8): .autoLPRecovery(uInt8)
			case .autoCounter: .autoCounter
			case .statusEffectsDisabled: .statusEffectsDisabled
		}
	}
}

extension DCL.Unpacked.Vivosaur.PassiveAbility: Codable {
	enum CodingKeys: CodingKey {
		case type
		case argument
	}
	
	enum DecodingError: Error {
		case invalidType(String)
		case missingArgument(forType: String)
		
		// TODO: custom description
	}
	
	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let type = try container.decode(String.self, forKey: .type)
		let argument = try container.decodeIfPresent(UInt8.self, forKey: .argument)
		
		self = switch type {
			case "nothing":
					.nothing
			case "fpPlus":
					.fpPlus(try argument.orElseThrow(DecodingError.missingArgument(forType: type)))
			case "partingBlow":
					.partingBlow(try argument.orElseThrow(DecodingError.missingArgument(forType: type)))
			case "autoLPRecovery":
					.autoLPRecovery(try argument.orElseThrow(DecodingError.missingArgument(forType: type)))
			case "autoCounter":
					.autoCounter
			case "statusEffectsDisabled":
					.statusEffectsDisabled
			default:
				throw DecodingError.invalidType(type)
		}
	}
	
	func encode(to encoder: any Encoder) throws {
		let (type, argument): (String, UInt8?) = switch self {
			case .nothing: ("nothing", nil)
			case .fpPlus(let uInt8): ("fpPlus", uInt8)
			case .partingBlow(let uInt8): ("partingBlow", uInt8)
			case .autoLPRecovery(let uInt8): ("autoLPRecovery", uInt8)
			case .autoCounter: ("autoCounter", nil)
			case .statusEffectsDisabled: ("statusEffectsDisabled", nil)
		}
		
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(type, forKey: .type)
		try container.encodeIfPresent(argument, forKey: .argument)
	}
}

extension DCL.Unpacked.Vivosaur.SupportEffects {
	init(_ packed: DCL.Packed.Vivosaur.SupportEffects) {
		attack = packed.attack
		defense = packed.defense
		accuracy = packed.accuracy
		evasion = packed.evasion
	}
}
