import BinaryParser

// etc/creature_defs
enum DCL_FFC {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "DCL"
		
		var unknown01: Int16
		var unknown02: Int16
		var unknown03: Int16
		var unknown04: Int16
		var unknown05: Int16
		var unknown06: Int16
		var unknown07: Int16
		var unknown08: Int16
		var unknown09: Int16
		var unknown10: Int16
		var unknown11: Int16
		var unknown12: Int16
		var unknown13: Int16
		var unknown14: Int16
		
		var vivosaurCount: UInt32
		var vivosaurOffsetsOffset: UInt32 = 0x28
		
		@Count(givenBy: \Self.vivosaurCount)
		@Offset(givenBy: \Self.vivosaurOffsetsOffset)
		var vivosaurOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.vivosaurOffsets)
		var vivosaurs: [Vivosaur]
		
		@BinaryConvertible
		struct Vivosaur {
			var isEntry: UInt8
			
			var element: Element
			
			var statAttack: Stat
			var statDefense: Stat
			var statAccuracy: Stat
			var statSpeed: Stat
			
			var critRate: UInt8
			var critRateForTypeAdvantage: UInt8
			
			// 0x14
			var linkChance: UInt8
			
			var sortOrderDiet: Diet
			
			var sortOrderEra: Era
			
			var sortOrderLP: UInt8
			
			// 0x18
			var sortOrderDigsite: Digsite // but maybe doesnt work?
			
			var staticBlueMove: BlueMove
			
			var range: Range
			
			var rangeMultiplier1: UInt8 // 0-3 tiles away?
			// 0x1c
			var rangeMultiplier2: UInt8 // 4-7 tiles away?
			var rangeMultiplier3: UInt8
			var rangeMultiplier4: UInt8
			var rangeMultiplier5: UInt8
			// 0x20
			var rangeMultiplier6: UInt8
			var rangeMultiplier7: UInt8
			var rangeMultiplier8: UInt8
			
			var immunityToPoison: UInt8 // bool
			// 0x24
			var immunityToSleep: UInt8
			var immunityToScare: UInt8
			var immunityToEnrage: UInt8
			var immunityToConfusion: UInt8
			// 0x28
			var immunityToExcite: UInt8
			var immunityToInfection: UInt8
			var immunityToInstantKO: UInt8
			
			var unknown02: UInt8
			// 0x2c
			var unknown03: UInt16
			var unknown04: UInt16
			
			// 0x30
			var defaultNameID: UInt16
			
			var unknown05: UInt16
			
			// 0x34
			var id: UInt16
			var superEvolvesIntoID: UInt16
			// 0x38
			var superEvolvesFromID: UInt16
			
			var modelID: UInt16
			
			// 0x3c
			var unknown06: UInt16
			var unknown07: UInt16
			
			// 0x40
			var spriteIDs: UInt16
			
			var animationPackID: UInt16
			
			// 0x44
			var unknown08: UInt16
			
			var colorPaletteForHead: UInt16
			// 0x48
			var colorPaletteForBody: UInt16
			var colorPaletteForArms: UInt16
			// 0x4c
			var colorPaletteForLegs: UInt16
			
			var teamSkillID: UInt16
			
			// 0x50
			var linkMoveID: UInt16
			
			var unknown09: UInt16
			// 0x54
			var abilityArgument: UInt16
//			- Nothing: Always 00
//			- FP Plus: (+Percent + 100) / 10
//			- Parting Blow: Percent / 10
//			- Auto LP Recovery: Percent
//			- Auto Counter: Since it is always 0x64 here, this is most likely the chance to trigger
//			- Elemental Boost: Always 00
//			- Position Lock: Always 00
//			- FP Absorb: Percent of incoming move's FP cost gained
//			- Solo Power: Always 00
//			- Berserker: This is the only ability where 0x55 may be something other than 00, since this is what move
//			Hopter always uses when woozy. By default, it is E7 01, i.e. Beak Stab.
//			- Enter with a Status: This represents the ID of the status. It matches up perfectly with the "primary"
//			effect table given in the attack_defs docs.
//			- Resurrect: Z-Rex has a 02 here, even though this ability activates after three turns. However, this is
//			similar to how Infection has a 04 despite it taking 5 turns to kill (see below), so we can safely say
//			that this controls how many turns it takes to come back.
			
			var sortOrderName: UInt16
			
			// 0x58
			var unknown10: UInt16
			var unknown11: UInt16
			
			// 0x5c
			var teams: Teams
			
			// 0x60
			var positionInFormationScreen: Position
			var positionInStatsScreen: Position
			var positionInFossilary: Position
			var positionInRevivalScreen: Position
			
			// 0x90
			var shadowSize: FixedPoint2012
			
			var moveCount: UInt32
			var movesOffset: UInt32 = 0xBC
			
			var moveLearningLevelCount: UInt32
			// 0xa0
			var moveLearningLevelsOffset: UInt32
			
			var allySupportEffectsOffset: UInt32
			var enemySupportEffectsOffset: UInt32
			
			var moveListOrderCount: UInt32
			// 0xb0
			var moveListOrderOffset: UInt32
			
			var rankCount: UInt32
			var healthAtEachRankOffset: UInt32
			
			@Count(givenBy: \Self.moveCount)
			@Offset(givenBy: \Self.movesOffset)
			var moves: [UInt16]
			
			@Count(givenBy: \Self.moveLearningLevelCount)
			@Offset(givenBy: \Self.moveLearningLevelsOffset)
			var moveLearningLevels: [UInt16]
			
			@If(\Self.allySupportEffectsOffset, is: .notEqualTo(0))
			@Offset(givenBy: \Self.allySupportEffectsOffset)
			var allySupportEffects: SupportEffects?
			
			@If(\Self.enemySupportEffectsOffset, is: .notEqualTo(0))
			@Offset(givenBy: \Self.enemySupportEffectsOffset)
			var enemySupportEffects: SupportEffects?
			
			@Count(givenBy: \Self.moveListOrderCount)
			@Offset(givenBy: \Self.moveListOrderOffset)
			var moveListOrder: [UInt8] // usually 123 or 1234
			
			@Count(givenBy: \Self.rankCount)
			@Offset(givenBy: \Self.healthAtEachRankOffset)
			var healthAtEachRank: [UInt16]
			
			enum Element: UInt8, RawRepresentable {
				case none, fire, air, earth, water, neutral, legendary
			}
			
			@BinaryConvertible
			struct Stat {
				var growthRate: UInt8
				var rank10Value: UInt8
				var rank01Value: UInt8
				var rank20Value: UInt8
			}
			
			enum Diet: UInt8, RawRepresentable {
				case none, carnivore, herbivore, omnivore, unknown
			}
			
			enum Era: UInt8, RawRepresentable {
				case none, noTimePeriod, cenozoicQuaternary, cenozoicNeogene, cenozoicPaleogene, mesozoicCreataceous, mesozoicJurassic, mesozoicTriassic, paleozoicPermian, paleozoicCarboniferous, paleozoicDevonian, paleozoicOrdovician, paleozoicCambrian
			}
			
			enum Digsite: UInt8, RawRepresentable {
				case none, bonusDataAndDebugs, zongazongaRematch, lolaFight, lesterFight, coleFight, robinsonFight, sideMission, superRevival, donationPointsVivosaur, seabedCavern, bbBrigadeBase, unused, bonehemoth, icegripPlateau, hotSpringHeights, dustyDunes, rainbowCanyon, mtKrakanak, petrifiedWoods, stonePyramid, jungleLabyrinth, treasureLake
			}
			
			enum BlueMove: UInt8, RawRepresentable {
				case none, nothing, japaneseForViewEnemyDetailsDuringBattle, japaneseForDinosaurPlacementRandomization, fpPlus, partingBlow, autoLPRecovery, autoCounter, japaneseForStatusEffectAbilityChangeDisabled, japaneseForSupportAttackRateUp, japaneseForMakesItEasierToObtainCertainKindsOfRocks, japaneseForIncreasedMovementSpeed, japaneseForCanOvercomeObstacles, elementalBoost, positionLock, fpAbsorb, soloPower, berserker, startWithAStatus, japaneseForIncreasedDamageAgainstSpecificAttributes, resurrect
			}
			
			enum Range: UInt8, RawRepresentable {
				case none, close, mid, long
			}
			
			@BinaryConvertible
			struct Teams: OptionSet {
				let rawValue: UInt32
				
				static let fireType      = Self(rawValue: 1 << 0)
				static let airType       = Self(rawValue: 1 << 1)
				static let earthType     = Self(rawValue: 1 << 2)
				static let waterType     = Self(rawValue: 1 << 3)
				static let neutralType   = Self(rawValue: 1 << 4)
				static let violent       = Self(rawValue: 1 << 5)
				static let group7        = Self(rawValue: 1 << 6)
				static let group8        = Self(rawValue: 1 << 7)
				static let group9        = Self(rawValue: 1 << 8)
				static let group10       = Self(rawValue: 1 << 9)
				static let group11       = Self(rawValue: 1 << 10)
				static let group12       = Self(rawValue: 1 << 11)
				static let group13       = Self(rawValue: 1 << 12)
				static let group14       = Self(rawValue: 1 << 13)
				static let group15       = Self(rawValue: 1 << 14)
				static let japanese      = Self(rawValue: 1 << 15)
				static let group17       = Self(rawValue: 1 << 16)
				static let group18       = Self(rawValue: 1 << 17)
				static let group19       = Self(rawValue: 1 << 18)
				static let cenozoic      = Self(rawValue: 1 << 19)
				static let group21       = Self(rawValue: 1 << 20)
				static let boney         = Self(rawValue: 1 << 21)
				static let zombie        = Self(rawValue: 1 << 22)
				static let poisonous     = Self(rawValue: 1 << 23)
				static let group25       = Self(rawValue: 1 << 24)
				static let group26       = Self(rawValue: 1 << 25)
				static let group27       = Self(rawValue: 1 << 26)
				static let group28       = Self(rawValue: 1 << 27)
				static let group29       = Self(rawValue: 1 << 28)
				static let dinaurians    = Self(rawValue: 1 << 29)
				static let feathered     = Self(rawValue: 1 << 30)
				static let unusedGroup32 = Self(rawValue: 1 << 31)
			}
			
			@BinaryConvertible
			struct Position {
				var y: FixedPoint2012
				var rotation: FixedPoint2012
				var z: FixedPoint2012
			}
			
			@BinaryConvertible
			struct SupportEffects {
				var attack: Int8
				var defense: Int8
				var accuracy: Int8
				var speed: Int8
			}
		}
	}
	
	struct Unpacked: Codable {
		var unknown01: Int16
		var unknown02: Int16
		var unknown03: Int16
		var unknown04: Int16
		var unknown05: Int16
		var unknown06: Int16
		var unknown07: Int16
		var unknown08: Int16
		var unknown09: Int16
		var unknown10: Int16
		var unknown11: Int16
		var unknown12: Int16
		var unknown13: Int16
		var unknown14: Int16
		
		var vivosaurs: [Vivosaur?]
		
		struct Vivosaur: Codable {
			var _defaultName: String?
			
			var isEntry: Bool
			
			var element: Element
			
			var statAttack: Stat
			var statDefense: Stat
			var statAccuracy: Stat
			var statSpeed: Stat
			
			var critRate: UInt8
			var critRateForTypeAdvantage: UInt8
			
			var linkChance: UInt8
			
			var sortOrderDiet: Diet
			
			var sortOrderEra: Era
			
			var sortOrderLP: UInt8
			
			var sortOrderDigsite: Digsite
			
			var staticBlueMove: BlueMove
			
			var range: Range
			
			var rangeMultiplier1: UInt8 // 0-3 tiles away?
			var rangeMultiplier2: UInt8 // 4-7 tiles away?
			var rangeMultiplier3: UInt8
			var rangeMultiplier4: UInt8
			var rangeMultiplier5: UInt8
			var rangeMultiplier6: UInt8
			var rangeMultiplier7: UInt8
			var rangeMultiplier8: UInt8
			
			var immunityToPoison: Bool
			var immunityToSleep: Bool
			var immunityToScare: Bool
			var immunityToEnrage: Bool
			var immunityToConfusion: Bool
			var immunityToExcite: Bool
			var immunityToInfection: Bool
			var immunityToInstantKO: Bool
			
			var unknown02: UInt8
			var unknown03: UInt16
			var unknown04: UInt16
			
			var defaultNameID: UInt16
			
			var unknown05: UInt16
			
			var id: UInt16
			var superEvolvesIntoID: UInt16
			var superEvolvesFromID: UInt16
			
			var modelID: UInt16
			
			var unknown06: UInt16
			var unknown07: UInt16
			
			var spriteIDs: UInt16
			
			var animationPackID: UInt16
			
			var unknown08: UInt16
			
			var colorPaletteForHead: UInt16
			var colorPaletteForBody: UInt16
			var colorPaletteForArms: UInt16
			var colorPaletteForLegs: UInt16
			
			var teamSkillID: UInt16
			
			var linkMoveID: UInt16
			
			var unknown09: UInt16
			var abilityArgument: UInt16
			
			var sortOrderName: UInt16
			
			var unknown10: UInt16
			var unknown11: UInt16
			
			var teams: [Team]
			
			var positionInFormationScreen: Position
			var positionInStatsScreen: Position
			var positionInFossilary: Position
			var positionInRevivalScreen: Position
			
			var shadowSize: Double
			
			var moves: [UInt16]
			
			var moveLearningLevels: [UInt16]
			
			var allySupportEffects: SupportEffects?
			
			var enemySupportEffects: SupportEffects?
			
			var moveListOrder: [UInt8]
			
			var healthAtEachRank: [UInt16]
			
			enum Element: String, Codable {
				case none, fire, air, earth, water, neutral, legendary
			}
			
			struct Stat: Codable {
				var growthRate: UInt8
				var rank10Value: UInt8
				var rank01Value: UInt8
				var rank20Value: UInt8
			}
			
			enum Diet: String, Codable {
				case none, carnivore, herbivore, omnivore, unknown
			}
			
			enum Era: String, Codable {
				case none, noTimePeriod, cenozoicQuaternary, cenozoicNeogene, cenozoicPaleogene, mesozoicCreataceous, mesozoicJurassic, mesozoicTriassic, paleozoicPermian, paleozoicCarboniferous, paleozoicDevonian, paleozoicOrdovician, paleozoicCambrian
			}
			
			enum Digsite: String, Codable {
				case none, bonusDataAndDebugs, zongazongaRematch, lolaFight, lesterFight, coleFight, robinsonFight, sideMission, superRevival, donationPointsVivosaur, seabedCavern, bbBrigadeBase, unused, bonehemoth, icegripPlateau, hotSpringHeights, dustyDunes, rainbowCanyon, mtKrakanak, petrifiedWoods, stonePyramid, jungleLabyrinth, treasureLake
			}
			
			enum BlueMove: String, Codable {
				case none, nothing, japaneseForViewEnemyDetailsDuringBattle, japaneseForDinosaurPlacementRandomization, fpPlus, partingBlow, autoLPRecovery, autoCounter, japaneseForStatusEffectAbilityChangeDisabled, japaneseForSupportAttackRateUp, japaneseForMakesItEasierToObtainCertainKindsOfRocks, japaneseForIncreasedMovementSpeed, japaneseForCanOvercomeObstacles, elementalBoost, positionLock, fpAbsorb, soloPower, berserker, startWithAStatus, japaneseForIncreasedDamageAgainstSpecificAttributes, resurrect
			}
			
			enum Range: String, Codable {
				case none, close, mid, long
			}
			
			enum Team: String, Codable, CaseIterable {
				case fireType      = "fire-type (1)"
				case airType       = "air-type (2)"
				case earthType     = "earth-type (3)"
				case waterType     = "water-type (4)"
				case neutralType   = "neutral-type (5)"
				case violent       = "violent (6)"
				case group7        = "group7"
				case group8        = "group8"
				case group9        = "group9"
				case group10       = "group10"
				case group11       = "group11"
				case group12       = "group12"
				case group13       = "group13"
				case group14       = "group14"
				case group15       = "group15"
				case japanese      = "japanese (16)"
				case group17       = "group17"
				case group18       = "group18"
				case group19       = "group19"
				case cenozoic      = "cenozoic"
				case group21       = "group21"
				case boney         = "boney (22)"
				case zombie        = "zombie (23)"
				case poisonous     = "poisonous (24)"
				case group25       = "group25"
				case group26       = "group26"
				case group27       = "group27"
				case group28       = "group28"
				case group29       = "group29"
				case dinaurians    = "dinaurians (30)"
				case feathered     = "feathered (31)"
				case unusedGroup32 = "unusedGroup32"
			}
			
			struct Position: Codable {
				var y: Double
				var rotation: Double
				var z: Double
			}
			
			struct SupportEffects: Codable {
				var attack: Int8
				var defense: Int8
				var accuracy: Int8
				var speed: Int8
			}
		}
	}
}

// MARK: packed
extension DCL_FFC.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> DCL_FFC.Unpacked {
		DCL_FFC.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: DCL_FFC.Unpacked, configuration: Configuration) {
		unknown01 = unpacked.unknown01
		unknown02 = unpacked.unknown02
		unknown03 = unpacked.unknown03
		unknown04 = unpacked.unknown04
		unknown05 = unpacked.unknown05
		unknown06 = unpacked.unknown06
		unknown07 = unpacked.unknown07
		unknown08 = unpacked.unknown08
		unknown09 = unpacked.unknown09
		unknown10 = unpacked.unknown10
		unknown11 = unpacked.unknown11
		unknown12 = unpacked.unknown12
		unknown13 = unpacked.unknown13
		unknown14 = unpacked.unknown14
		
		vivosaurCount = UInt32(unpacked.vivosaurs.count)
		
		vivosaurs = unpacked.vivosaurs.map(Vivosaur.init)
		
		vivosaurOffsets = makeOffsets(
			start: vivosaurOffsetsOffset + vivosaurCount * 4,
			sizes: vivosaurs.map { $0.size() },
			alignedTo: 4
		)
	}
}

extension DCL_FFC.Packed.Vivosaur {
	static let null = Self(isEntry: 0, element: .none, statAttack: .null, statDefense: .null, statAccuracy: .null, statSpeed: .null, critRate: 0, critRateForTypeAdvantage: 0, linkChance: 0, sortOrderDiet: .none, sortOrderEra: .none, sortOrderLP: 0, sortOrderDigsite: .none, staticBlueMove: .none, range: .none, rangeMultiplier1: 0, rangeMultiplier2: 0, rangeMultiplier3: 0, rangeMultiplier4: 0, rangeMultiplier5: 0, rangeMultiplier6: 0, rangeMultiplier7: 0, rangeMultiplier8: 0, immunityToPoison: 0, immunityToSleep: 0, immunityToScare: 0, immunityToEnrage: 0, immunityToConfusion: 0, immunityToExcite: 0, immunityToInfection: 0, immunityToInstantKO: 0, unknown02: 0, unknown03: 0, unknown04: 0, defaultNameID: 0, unknown05: 0, id: 0, superEvolvesIntoID: 0, superEvolvesFromID: 0, modelID: 0, unknown06: 0, unknown07: 0, spriteIDs: 0, animationPackID: 0, unknown08: 0, colorPaletteForHead: 0, colorPaletteForBody: 0, colorPaletteForArms: 0, colorPaletteForLegs: 0, teamSkillID: 0, linkMoveID: 0, unknown09: 0, abilityArgument: 0, sortOrderName: 0, unknown10: 0, unknown11: 0, teams: [], positionInFormationScreen: .null, positionInStatsScreen: .null, positionInFossilary: .null, positionInRevivalScreen: .null, shadowSize: 0, moveCount: 0, moveLearningLevelCount: 0, moveLearningLevelsOffset: 0xBC, allySupportEffectsOffset: 0, enemySupportEffectsOffset: 0, moveListOrderCount: 0, moveListOrderOffset: 0xBC, rankCount: 0, healthAtEachRankOffset: 0xBC, moves: [], moveLearningLevels: [], moveListOrder: [], healthAtEachRank: [])
	
	fileprivate init(_ unpacked: DCL_FFC.Unpacked.Vivosaur?) {
		guard let unpacked else {
			self = .null
			return
		}
		
		isEntry = unpacked.isEntry ? 1 : 0
		
		element = Element(unpacked.element)
		
		statAttack = Stat(unpacked.statAttack)
		statDefense = Stat(unpacked.statDefense)
		statAccuracy = Stat(unpacked.statAccuracy)
		statSpeed = Stat(unpacked.statSpeed)
		
		critRate = unpacked.critRate
		critRateForTypeAdvantage = unpacked.critRateForTypeAdvantage
		
		linkChance = unpacked.linkChance
		
		sortOrderDiet = Diet(unpacked.sortOrderDiet)
		
		sortOrderEra = Era(unpacked.sortOrderEra)
		
		sortOrderLP = unpacked.sortOrderLP
		
		sortOrderDigsite = Digsite(unpacked.sortOrderDigsite)
		
		staticBlueMove = BlueMove(unpacked.staticBlueMove)
		
		range = Range(unpacked.range)
		
		rangeMultiplier1 = unpacked.rangeMultiplier1
		rangeMultiplier2 = unpacked.rangeMultiplier2
		rangeMultiplier3 = unpacked.rangeMultiplier3
		rangeMultiplier4 = unpacked.rangeMultiplier4
		rangeMultiplier5 = unpacked.rangeMultiplier5
		rangeMultiplier6 = unpacked.rangeMultiplier6
		rangeMultiplier7 = unpacked.rangeMultiplier7
		rangeMultiplier8 = unpacked.rangeMultiplier8
		
		immunityToPoison = unpacked.immunityToPoison ? 1 : 0
		immunityToSleep = unpacked.immunityToSleep ? 1 : 0
		immunityToScare = unpacked.immunityToScare ? 1 : 0
		immunityToEnrage = unpacked.immunityToEnrage ? 1 : 0
		immunityToConfusion = unpacked.immunityToConfusion ? 1 : 0
		immunityToExcite = unpacked.immunityToExcite ? 1 : 0
		immunityToInfection = unpacked.immunityToInfection ? 1 : 0
		immunityToInstantKO = unpacked.immunityToInstantKO ? 1 : 0
		
		unknown02 = unpacked.unknown02
		unknown03 = unpacked.unknown03
		unknown04 = unpacked.unknown04
		
		defaultNameID = unpacked.defaultNameID
		
		unknown05 = unpacked.unknown05
		
		id = unpacked.id
		superEvolvesIntoID = unpacked.superEvolvesIntoID
		superEvolvesFromID = unpacked.superEvolvesFromID
		
		modelID = unpacked.modelID
		
		unknown06 = unpacked.unknown06
		unknown07 = unpacked.unknown07
		
		spriteIDs = unpacked.spriteIDs
		
		animationPackID = unpacked.animationPackID
		
		unknown08 = unpacked.unknown08
		
		colorPaletteForHead = unpacked.colorPaletteForHead
		colorPaletteForBody = unpacked.colorPaletteForBody
		colorPaletteForArms = unpacked.colorPaletteForArms
		colorPaletteForLegs = unpacked.colorPaletteForLegs
		
		teamSkillID = unpacked.teamSkillID
		
		linkMoveID = unpacked.linkMoveID
		
		unknown09 = unpacked.unknown09
		abilityArgument = unpacked.abilityArgument
		
		sortOrderName = unpacked.sortOrderName
		
		unknown10 = unpacked.unknown10
		unknown11 = unpacked.unknown11
		
		teams = unpacked.teams
			.map(Teams.init)
			.reduce([]) { $0.union($1) }
		
		positionInFormationScreen = Position(unpacked.positionInFormationScreen)
		positionInStatsScreen = Position(unpacked.positionInStatsScreen)
		positionInFossilary = Position(unpacked.positionInFossilary)
		positionInRevivalScreen = Position(unpacked.positionInRevivalScreen)
		
		shadowSize = FixedPoint2012(unpacked.shadowSize)
		
		moveCount = UInt32(unpacked.moves.count)
		
		moveLearningLevelCount = UInt32(unpacked.moveLearningLevels.count)
		moveLearningLevelsOffset = movesOffset + (moveCount * 2).roundedUpToTheNearest(4)
		
		let moveLearningLevelsEndOffset = moveLearningLevelsOffset + (moveLearningLevelCount * 2).roundedUpToTheNearest(4)
		
		let allySupportEffectsEndOffset: UInt32
		if unpacked.allySupportEffects == nil {
			allySupportEffectsOffset = 0
			allySupportEffectsEndOffset = 0
		} else {
			allySupportEffectsOffset = moveLearningLevelsEndOffset
			allySupportEffectsEndOffset = allySupportEffectsOffset + 4
		}
		
		let enemySupportEffectsEndOffset: UInt32
		if unpacked.enemySupportEffects == nil {
			enemySupportEffectsOffset = 0
			enemySupportEffectsEndOffset = 0
		} else {
			enemySupportEffectsOffset = max(moveLearningLevelsEndOffset, allySupportEffectsEndOffset)
			enemySupportEffectsEndOffset = enemySupportEffectsOffset + 4
		}
		
		moveListOrderCount = UInt32(unpacked.moveListOrder.count)
		moveListOrderOffset = max(moveLearningLevelsEndOffset, allySupportEffectsEndOffset, enemySupportEffectsEndOffset)
		
		rankCount = UInt32(unpacked.healthAtEachRank.count)
		healthAtEachRankOffset = moveListOrderOffset + moveListOrderCount.roundedUpToTheNearest(4)
		
		moves = unpacked.moves
		
		moveLearningLevels = unpacked.moveLearningLevels
		
		allySupportEffects = unpacked.allySupportEffects.map(SupportEffects.init)
		
		enemySupportEffects = unpacked.enemySupportEffects.map(SupportEffects.init)
		
		moveListOrder = unpacked.moveListOrder
		
		healthAtEachRank = unpacked.healthAtEachRank
	}
	
	func size() -> UInt32 {
		healthAtEachRankOffset + rankCount * 2
	}
}

extension DCL_FFC.Packed.Vivosaur.Element {
	fileprivate init(_ unpacked: DCL_FFC.Unpacked.Vivosaur.Element) {
		self = switch unpacked {
			case .none: .none
			case .fire: .fire
			case .air: .air
			case .earth: .earth
			case .water: .water
			case .neutral: .neutral
			case .legendary: .legendary
		}
	}
}

extension DCL_FFC.Packed.Vivosaur.Stat {
	static let null = Self(growthRate: 0, rank10Value: 0, rank01Value: 0, rank20Value: 0)
	
	fileprivate init(_ unpacked: DCL_FFC.Unpacked.Vivosaur.Stat) {
		growthRate = unpacked.growthRate
		rank10Value = unpacked.rank10Value
		rank01Value = unpacked.rank01Value
		rank20Value = unpacked.rank20Value
	}
}

extension DCL_FFC.Packed.Vivosaur.Diet {
	fileprivate init(_ unpacked: DCL_FFC.Unpacked.Vivosaur.Diet) {
		self = switch unpacked {
			case .none: .none
			case .carnivore: .carnivore
			case .herbivore: .herbivore
			case .omnivore: .omnivore
			case .unknown: .unknown
		}
	}
}

extension DCL_FFC.Packed.Vivosaur.Era {
	fileprivate init(_ unpacked: DCL_FFC.Unpacked.Vivosaur.Era) {
		self = switch unpacked {
			case .none: .none
			case .noTimePeriod: .noTimePeriod
			case .cenozoicQuaternary: .cenozoicQuaternary
			case .cenozoicNeogene: .cenozoicNeogene
			case .cenozoicPaleogene: .cenozoicPaleogene
			case .mesozoicCreataceous: .mesozoicCreataceous
			case .mesozoicJurassic: .mesozoicJurassic
			case .mesozoicTriassic: .mesozoicTriassic
			case .paleozoicPermian: .paleozoicPermian
			case .paleozoicCarboniferous: .paleozoicCarboniferous
			case .paleozoicDevonian: .paleozoicDevonian
			case .paleozoicOrdovician: .paleozoicOrdovician
			case .paleozoicCambrian: .paleozoicCambrian
		}
	}
}

extension DCL_FFC.Packed.Vivosaur.Digsite {
	fileprivate init(_ unpacked: DCL_FFC.Unpacked.Vivosaur.Digsite) {
		self = switch unpacked {
			case .none: .none
			case .bonusDataAndDebugs: .bonusDataAndDebugs
			case .zongazongaRematch: .zongazongaRematch
			case .lolaFight: .lolaFight
			case .lesterFight: .lesterFight
			case .coleFight: .coleFight
			case .robinsonFight: .robinsonFight
			case .sideMission: .sideMission
			case .superRevival: .superRevival
			case .donationPointsVivosaur: .donationPointsVivosaur
			case .seabedCavern: .seabedCavern
			case .bbBrigadeBase: .bbBrigadeBase
			case .unused: .unused
			case .bonehemoth: .bonehemoth
			case .icegripPlateau: .icegripPlateau
			case .hotSpringHeights: .hotSpringHeights
			case .dustyDunes: .dustyDunes
			case .rainbowCanyon: .rainbowCanyon
			case .mtKrakanak: .mtKrakanak
			case .petrifiedWoods: .petrifiedWoods
			case .stonePyramid: .stonePyramid
			case .jungleLabyrinth: .jungleLabyrinth
			case .treasureLake: .treasureLake
		}
	}
}

extension DCL_FFC.Packed.Vivosaur.BlueMove {
	fileprivate init(_ unpacked: DCL_FFC.Unpacked.Vivosaur.BlueMove) {
		self = switch unpacked {
			case .none: .none
			case .nothing: .nothing
			case .japaneseForViewEnemyDetailsDuringBattle: .japaneseForViewEnemyDetailsDuringBattle
			case .japaneseForDinosaurPlacementRandomization: .japaneseForDinosaurPlacementRandomization
			case .fpPlus: .fpPlus
			case .partingBlow: .partingBlow
			case .autoLPRecovery: .autoLPRecovery
			case .autoCounter: .autoCounter
			case .japaneseForStatusEffectAbilityChangeDisabled: .japaneseForStatusEffectAbilityChangeDisabled
			case .japaneseForSupportAttackRateUp: .japaneseForSupportAttackRateUp
			case .japaneseForMakesItEasierToObtainCertainKindsOfRocks: .japaneseForMakesItEasierToObtainCertainKindsOfRocks
			case .japaneseForIncreasedMovementSpeed: .japaneseForIncreasedMovementSpeed
			case .japaneseForCanOvercomeObstacles: .japaneseForCanOvercomeObstacles
			case .elementalBoost: .elementalBoost
			case .positionLock: .positionLock
			case .fpAbsorb: .fpAbsorb
			case .soloPower: .soloPower
			case .berserker: .berserker
			case .startWithAStatus: .startWithAStatus
			case .japaneseForIncreasedDamageAgainstSpecificAttributes: .japaneseForIncreasedDamageAgainstSpecificAttributes
			case .resurrect: .resurrect
		}
	}
}

extension DCL_FFC.Packed.Vivosaur.Range {
	fileprivate init(_ unpacked: DCL_FFC.Unpacked.Vivosaur.Range) {
		self = switch unpacked {
			case .none: .none
			case .close: .close
			case .mid: .mid
			case .long: .long
		}
	}
}

extension DCL_FFC.Packed.Vivosaur.Teams {
	fileprivate init(_ unpacked: DCL_FFC.Unpacked.Vivosaur.Team) {
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
			case .group17: .group17
			case .group18: .group18
			case .group19: .group19
			case .cenozoic: .cenozoic
			case .group21: .group21
			case .boney: .boney
			case .zombie: .zombie
			case .poisonous: .poisonous
			case .group25: .group25
			case .group26: .group26
			case .group27: .group27
			case .group28: .group28
			case .group29: .group29
			case .dinaurians: .dinaurians
			case .feathered: .feathered
			case .unusedGroup32: .unusedGroup32
		}
	}
}

extension DCL_FFC.Packed.Vivosaur.Position {
	static let null = Self(y: 0, rotation: 0, z: 0)
	
	fileprivate init(_ unpacked: DCL_FFC.Unpacked.Vivosaur.Position) {
		y = FixedPoint2012(unpacked.y)
		rotation = FixedPoint2012(unpacked.rotation)
		z = FixedPoint2012(unpacked.z)
	}
}

extension DCL_FFC.Packed.Vivosaur.SupportEffects {
	fileprivate init(_ unpacked: DCL_FFC.Unpacked.Vivosaur.SupportEffects) {
		attack = unpacked.attack
		defense = unpacked.defense
		accuracy = unpacked.accuracy
		speed = unpacked.speed
	}
}

// MARK: unpacked
extension DCL_FFC.Unpacked: ProprietaryFileData {
	static let fileExtension = ".dcl.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: Configuration) -> DCL_FFC.Packed {
		DCL_FFC.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: DCL_FFC.Packed, configuration: Configuration) {
		unknown01 = packed.unknown01
		unknown02 = packed.unknown02
		unknown03 = packed.unknown03
		unknown04 = packed.unknown04
		unknown05 = packed.unknown05
		unknown06 = packed.unknown06
		unknown07 = packed.unknown07
		unknown08 = packed.unknown08
		unknown09 = packed.unknown09
		unknown10 = packed.unknown10
		unknown11 = packed.unknown11
		unknown12 = packed.unknown12
		unknown13 = packed.unknown13
		unknown14 = packed.unknown14
		
		vivosaurs = packed.vivosaurs.map(Vivosaur.init)
	}
}

extension DCL_FFC.Unpacked.Vivosaur {
	fileprivate init?(_ packed: DCL_FFC.Packed.Vivosaur) {
		isEntry = packed.isEntry > 0
		
		guard isEntry else { return nil }
		
		element = Element(packed.element)
		
		statAttack = Stat(packed.statAttack)
		statDefense = Stat(packed.statDefense)
		statAccuracy = Stat(packed.statAccuracy)
		statSpeed = Stat(packed.statSpeed)
		
		critRate = packed.critRate
		critRateForTypeAdvantage = packed.critRateForTypeAdvantage
		
		linkChance = packed.linkChance
		
		sortOrderDiet = Diet(packed.sortOrderDiet)
		
		sortOrderEra = Era(packed.sortOrderEra)
		
		sortOrderLP = packed.sortOrderLP
		
		sortOrderDigsite = Digsite(packed.sortOrderDigsite)
		
		staticBlueMove = BlueMove(packed.staticBlueMove)
		
		range = Range(packed.range)
		
		rangeMultiplier1 = packed.rangeMultiplier1
		rangeMultiplier2 = packed.rangeMultiplier2
		rangeMultiplier3 = packed.rangeMultiplier3
		rangeMultiplier4 = packed.rangeMultiplier4
		rangeMultiplier5 = packed.rangeMultiplier5
		rangeMultiplier6 = packed.rangeMultiplier6
		rangeMultiplier7 = packed.rangeMultiplier7
		rangeMultiplier8 = packed.rangeMultiplier8
		
		immunityToPoison = packed.immunityToPoison > 0
		immunityToSleep = packed.immunityToSleep > 0
		immunityToScare = packed.immunityToScare > 0
		immunityToEnrage = packed.immunityToEnrage > 0
		immunityToConfusion = packed.immunityToConfusion > 0
		immunityToExcite = packed.immunityToExcite > 0
		immunityToInfection = packed.immunityToInfection > 0
		immunityToInstantKO = packed.immunityToInstantKO > 0
		
		unknown02 = packed.unknown02
		unknown03 = packed.unknown03
		unknown04 = packed.unknown04
		
		defaultNameID = packed.defaultNameID
		
		unknown05 = packed.unknown05
		
		id = packed.id
		superEvolvesIntoID = packed.superEvolvesIntoID
		superEvolvesFromID = packed.superEvolvesFromID
		
		modelID = packed.modelID
		
		unknown06 = packed.unknown06
		unknown07 = packed.unknown07
		
		spriteIDs = packed.spriteIDs
		
		animationPackID = packed.animationPackID
		
		unknown08 = packed.unknown08
		
		colorPaletteForHead = packed.colorPaletteForHead
		colorPaletteForBody = packed.colorPaletteForBody
		colorPaletteForArms = packed.colorPaletteForArms
		colorPaletteForLegs = packed.colorPaletteForLegs
		
		teamSkillID = packed.teamSkillID
		
		linkMoveID = packed.linkMoveID
		
		unknown09 = packed.unknown09
		abilityArgument = packed.abilityArgument
		
		sortOrderName = packed.sortOrderName
		
		unknown10 = packed.unknown10
		unknown11 = packed.unknown11
		
		teams = [Team](packed.teams)
		
		positionInFormationScreen = Position(packed.positionInFormationScreen)
		positionInStatsScreen = Position(packed.positionInStatsScreen)
		positionInFossilary = Position(packed.positionInFossilary)
		positionInRevivalScreen = Position(packed.positionInRevivalScreen)
		
		shadowSize = Double(packed.shadowSize)
		
		moves = packed.moves
		
		moveLearningLevels = packed.moveLearningLevels
		
		allySupportEffects = packed.allySupportEffects.map(SupportEffects.init)
		
		enemySupportEffects = packed.enemySupportEffects.map(SupportEffects.init)
		
		moveListOrder = packed.moveListOrder
		
		healthAtEachRank = packed.healthAtEachRank
	}
}

extension DCL_FFC.Unpacked.Vivosaur.Element {
	fileprivate init(_ packed: DCL_FFC.Packed.Vivosaur.Element) {
		self = switch packed {
			case .none: .none
			case .fire: .fire
			case .air: .air
			case .earth: .earth
			case .water: .water
			case .neutral: .neutral
			case .legendary: .legendary
		}
	}
}

extension DCL_FFC.Unpacked.Vivosaur.Stat {
	fileprivate init(_ packed: DCL_FFC.Packed.Vivosaur.Stat) {
		growthRate = packed.growthRate
		rank10Value = packed.rank10Value
		rank01Value = packed.rank01Value
		rank20Value = packed.rank20Value
	}
}

extension DCL_FFC.Unpacked.Vivosaur.Diet {
	fileprivate init(_ packed: DCL_FFC.Packed.Vivosaur.Diet) {
		self = switch packed {
			case .none: .none
			case .carnivore: .carnivore
			case .herbivore: .herbivore
			case .omnivore: .omnivore
			case .unknown: .unknown
		}
	}
}

extension DCL_FFC.Unpacked.Vivosaur.Era {
	fileprivate init(_ packed: DCL_FFC.Packed.Vivosaur.Era) {
		self = switch packed {
			case .none: .none
			case .noTimePeriod: .noTimePeriod
			case .cenozoicQuaternary: .cenozoicQuaternary
			case .cenozoicNeogene: .cenozoicNeogene
			case .cenozoicPaleogene: .cenozoicPaleogene
			case .mesozoicCreataceous: .mesozoicCreataceous
			case .mesozoicJurassic: .mesozoicJurassic
			case .mesozoicTriassic: .mesozoicTriassic
			case .paleozoicPermian: .paleozoicPermian
			case .paleozoicCarboniferous: .paleozoicCarboniferous
			case .paleozoicDevonian: .paleozoicDevonian
			case .paleozoicOrdovician: .paleozoicOrdovician
			case .paleozoicCambrian: .paleozoicCambrian
		}
	}
}

extension DCL_FFC.Unpacked.Vivosaur.Digsite {
	fileprivate init(_ packed: DCL_FFC.Packed.Vivosaur.Digsite) {
		self = switch packed {
			case .none: .none
			case .bonusDataAndDebugs: .bonusDataAndDebugs
			case .zongazongaRematch: .zongazongaRematch
			case .lolaFight: .lolaFight
			case .lesterFight: .lesterFight
			case .coleFight: .coleFight
			case .robinsonFight: .robinsonFight
			case .sideMission: .sideMission
			case .superRevival: .superRevival
			case .donationPointsVivosaur: .donationPointsVivosaur
			case .seabedCavern: .seabedCavern
			case .bbBrigadeBase: .bbBrigadeBase
			case .unused: .unused
			case .bonehemoth: .bonehemoth
			case .icegripPlateau: .icegripPlateau
			case .hotSpringHeights: .hotSpringHeights
			case .dustyDunes: .dustyDunes
			case .rainbowCanyon: .rainbowCanyon
			case .mtKrakanak: .mtKrakanak
			case .petrifiedWoods: .petrifiedWoods
			case .stonePyramid: .stonePyramid
			case .jungleLabyrinth: .jungleLabyrinth
			case .treasureLake: .treasureLake
		}
	}
}

extension DCL_FFC.Unpacked.Vivosaur.BlueMove {
	fileprivate init(_ packed: DCL_FFC.Packed.Vivosaur.BlueMove) {
		self = switch packed {
			case .none: .none
			case .nothing: .nothing
			case .japaneseForViewEnemyDetailsDuringBattle: .japaneseForViewEnemyDetailsDuringBattle
			case .japaneseForDinosaurPlacementRandomization: .japaneseForDinosaurPlacementRandomization
			case .fpPlus: .fpPlus
			case .partingBlow: .partingBlow
			case .autoLPRecovery: .autoLPRecovery
			case .autoCounter: .autoCounter
			case .japaneseForStatusEffectAbilityChangeDisabled: .japaneseForStatusEffectAbilityChangeDisabled
			case .japaneseForSupportAttackRateUp: .japaneseForSupportAttackRateUp
			case .japaneseForMakesItEasierToObtainCertainKindsOfRocks: .japaneseForMakesItEasierToObtainCertainKindsOfRocks
			case .japaneseForIncreasedMovementSpeed: .japaneseForIncreasedMovementSpeed
			case .japaneseForCanOvercomeObstacles: .japaneseForCanOvercomeObstacles
			case .elementalBoost: .elementalBoost
			case .positionLock: .positionLock
			case .fpAbsorb: .fpAbsorb
			case .soloPower: .soloPower
			case .berserker: .berserker
			case .startWithAStatus: .startWithAStatus
			case .japaneseForIncreasedDamageAgainstSpecificAttributes: .japaneseForIncreasedDamageAgainstSpecificAttributes
			case .resurrect: .resurrect
		}
	}
}

extension DCL_FFC.Unpacked.Vivosaur.Range {
	fileprivate init(_ packed: DCL_FFC.Packed.Vivosaur.Range) {
		self = switch packed {
			case .none: .none
			case .close: .close
			case .mid: .mid
			case .long: .long
		}
	}
}

extension [DCL_FFC.Unpacked.Vivosaur.Team] {
	fileprivate init(_ packed: DCL_FFC.Packed.Vivosaur.Teams) {
		self = DCL_FFC.Unpacked.Vivosaur.Team.allCases
			.filter { packed.contains(DCL_FFC.Packed.Vivosaur.Teams($0)) }
	}
}

extension DCL_FFC.Unpacked.Vivosaur.Position {
	fileprivate init(_ packed: DCL_FFC.Packed.Vivosaur.Position) {
		y = Double(packed.y)
		rotation = Double(packed.rotation)
		z = Double(packed.z)
	}
}

extension DCL_FFC.Unpacked.Vivosaur.SupportEffects {
	fileprivate init(_ packed: DCL_FFC.Packed.Vivosaur.SupportEffects) {
		attack = packed.attack
		defense = packed.defense
		accuracy = packed.accuracy
		speed = packed.speed
	}
}
