import BinaryParser

struct DCL {
	var unknown1: UInt32
	var unknown2: UInt32
	var unknown3: UInt32
	var unknown4: UInt32
	var unknown5: UInt32
	var unknown6: UInt32
	var unknown7: UInt32
	var unknown8: UInt32
	
	var vivosaurs: [Vivosaur]
	
	struct Vivosaur: Codable {}
	
	@BinaryConvertible
	struct Binary {
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
		
		// -1 and +4 to skip the first vivo TODO: this should be temporary, right?
		@Count(givenBy: \Self.vivosaurCount, .minus(1))
		@Offset(givenBy: \Self.indicesOffset, .plus(4))
		var indices: [UInt32]
		
		@Offsets(givenBy: \Self.indices)
		var vivosaurs: [Vivosaur]
		
		// see https://github.com/opiter09/Fossil-Fighters-Documentation/blob/main/FF1/Creature_Defs.txt
		@BinaryConvertible
		struct Vivosaur {
			var id: UInt32
			
			var unknown1: UInt32 = 0
			var unknown2: UInt32 = 0
			
			var length: UInt8
			var element: Element
			var rank12HealthDividedBy2: UInt16
			
			var attack: Stat
			var defense: Stat
			var accuracy: Stat
			var evasion: Stat
			
			var crit: UInt8
			var critAgain: UInt8 // always the same as crit
			
			var linkChance: UInt8
			
			var unknown3: UInt8 = 100
			
			var teams: Teams
			
			var moveCount: UInt32 // always 3 or 4
			var skillIdsOffset: UInt32 = 0x8c
			
			var teamSkill: UInt32
			var linkSkill: UInt32
			
			var moveCountAgain: UInt32 // always the same as moveCount
			var long1234Offset: UInt32
			
			var unknown4: UInt32 = 1
			var unknown5: UInt32 = 0
			var unknown6: UInt32 = 0
			var unknown7: UInt32 = 0
			var unknown8: UInt32 = 0
			
			var allySupportEffectsOffset: UInt32
			var enemySupportEffectsOffset: UInt32
			
			var unknown9: UInt8 = 1
			var unknown10: UInt8 = 1
			var unknown11: UInt8 = 100
			var unknown12: UInt8 = 100
			
			var unknown13: UInt8 = 100
			
			var passiveAbility: PassiveAbility
			
			@Padding(bytes: 1)
			
			var statusChancesCount: UInt32 = 10
			var statusChancesOffset: UInt32
			
			var szDamageMultiplier: UInt32
			
			var unknown16: UInt32 = 40
			
			var moveCountAgainAgain: UInt32 // always the same as moveCount
			var moveListOrderOffset: UInt32
			
			var rankCount: UInt32 = 12
			var healthAtEachRankOffset: UInt32
			
			var displayNumber: UInt32 // only different than id for OP Frigi and OP Igno
			var alphabeticalOrder: UInt32
			
			@Count(givenBy: \Self.moveCount)
			@Offset(givenBy: \Self.skillIdsOffset)
			var skillIds: [UInt32]
			
			// what fossil you learn the move at (123/1234 for normal, 1111 for chickens)
			@Count(givenBy: \Self.moveCountAgain)
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
			// 2 bytes of padding here
			
			@Count(givenBy: \Self.moveCountAgainAgain)
			@Offset(givenBy: \Self.moveListOrderOffset)
			var moveListOrder: [UInt8] // always 123 or 1234
			
			@If(\Self.moveCount, is: .equalTo(3))
			var padding: UInt8? = 0
			
			@Count(givenBy: \Self.rankCount)
			@Offset(givenBy: \Self.healthAtEachRankOffset)
			var healthAtEachRank: [UInt16]
			
			enum Element: UInt8, BinaryConvertible {
				case fire = 1, air, earth, water, neutral, legendary
				
				enum InvalidElement: Error {
					case invalidElement(UInt8)
				}
				
				init(_ data: Datastream) throws {
					let rawByte = try data.read(UInt8.self)
					guard let element = Self(rawValue: rawByte) else {
						throw InvalidElement.invalidElement(rawByte)
					}
					self = element
				}
				
				func write(to data: Datawriter) {
					data.write(rawValue)
				}
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
				case nothing
				case fpPlus(UInt8) // (+percent + 100) / 10
				case partingBlow(UInt8) // percent / 10
				case autoLPRecovery(UInt8) // percent
				case autoCounter
				case statusEffectsDisabled
				
				enum InvalidDataError: Error {
					case invalidType(UInt8)
					case invalidArgument(UInt8, type: UInt8)
				}
				
				init(_ data: Datastream) throws {
					let type = try data.read(UInt8.self)
					let argument = try data.read(UInt8.self)
					
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
						case .nothing:
							data.write(1)
							data.write(0)
						case .fpPlus(let argument):
							data.write(4)
							data.write(argument)
						case .partingBlow(let argument):
							data.write(5)
							data.write(argument)
						case .autoLPRecovery(let argument):
							data.write(6)
							data.write(argument)
						case .autoCounter:
							data.write(7)
							data.write(100)
						case .statusEffectsDisabled:
							data.write(8)
							data.write(1)
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
		}
	}
}

// MARK: packed
extension DCL: ProprietaryFileData {
	static let fileExtension = ".dcl.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	init(_ binary: Binary) {
		unknown1 = binary.unknown1
		unknown2 = binary.unknown2
		unknown3 = binary.unknown3
		unknown4 = binary.unknown4
		unknown5 = binary.unknown5
		unknown6 = binary.unknown6
		unknown7 = binary.unknown7
		unknown8 = binary.unknown8
		
		vivosaurs = binary.vivosaurs.map(Vivosaur.init)
	}
}

extension DCL.Vivosaur {
	init(_ packed: DCL.Binary.Vivosaur) {}
}

extension DCL.Binary: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	init(_ dcl: DCL) {
		unknown1 = dcl.unknown1
		unknown2 = dcl.unknown2
		unknown3 = dcl.unknown3
		unknown4 = dcl.unknown4
		unknown5 = dcl.unknown5
		unknown6 = dcl.unknown6
		unknown7 = dcl.unknown7
		unknown8 = dcl.unknown8
		
		vivosaurCount = UInt32(dcl.vivosaurs.count)
		
//		vivosaurs = dcl.vivosaurs.map(Vivosaur.init)
		
		fatalError()
	}
}

// triggers a compiler bug in swift 5 mode with @Include
#if compiler(>=6)
extension DCL.Binary.Vivosaur {
	init(_ unpacked: DCL.Vivosaur) {
		fatalError("TODO:")
	}
}
#endif

// MARK: unpacked
extension DCL: Codable {
	// TODO: custom codable implementation?
}

fileprivate func nameForVivosaur(_ vivosaur: DCL.Binary.Vivosaur) -> String {
	vivosaurNames[Int(vivosaur.id)]
}
