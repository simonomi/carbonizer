import BinaryParser

// ff1-only
// https://github.com/opiter09/Fossil-Fighters-Documentation/blob/main/FF1/Battle%20Folder.txt
struct DBS {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "DBS"
		
		var fighter1Offset: UInt32
		
		var fighter2Offset: UInt32
		
		var music: Int32 // 0xC
		
		var unknown3: Int32
		var unknown4: Int32
		var unknown5: Int32
		var unknown6: Int32
		
		var unknown7: Int32
		var unknown8: Int32
		var unknown9: Int32
		var unknown10: Int32
		
		var arena: Int32 // 0x30
		
		var unknowns17Count: UInt32
		var unknowns17Offset: UInt32
		
		var requiredVivosaurCount: UInt32
		var requiredVivosaursOffset: UInt32
		
		var unknown11: Int32
		var unknown12: Int32
		var unknown13: Int32
		
		var unknown14: Int32 // 0x50
		var bpForWinning: Int32
		var unknown16: Int32
		
		@If(\Self.fighter1Offset, is: .notEqualTo(0))
		@Offset(givenBy: \Self.fighter1Offset)
		var fighter1: Fighter?
		
		@Offset(givenBy: \Self.fighter2Offset)
		var fighter2: Fighter
		
		@Count(givenBy: \Self.unknowns17Count)
		@Offset(givenBy: \Self.unknowns17Offset)
		var unknowns17: [Unknown]
		
		@Count(givenBy: \Self.requiredVivosaurCount)
		@Offset(givenBy: \Self.requiredVivosaursOffset)
		var requiredVivosaurs: [Int32]
		
		@BinaryConvertible
		struct Fighter {
			var vivosaurCount: UInt32
			var vivosaursOffset: UInt32 = 0x38
			
			var name: Int32 // index into dtx
			var rank: Int32
			
			var vivosaurCount2: UInt32
			var aiSetsOffset: UInt32
			
			var vivosaurCount3: UInt32
			var interLevelBattlePointsPerVivosaurOffset: UInt32
			
			var vivosaurCount4: UInt32
			var movesUnlockedPerVivosaurOffset: UInt32
			
			var unknowns3Count: UInt32 = 2
			var unknowns3Offset: UInt32
			
			var icon: Int32
			var minimumVivosaurHealth: Int32 // nonzero in 0401
			
			@Count(givenBy: \Self.vivosaurCount)
			@Offset(givenBy: \Self.vivosaursOffset)
			var vivosaurs: [Vivosaur]
			
			@Count(givenBy: \Self.vivosaurCount2)
			@Offset(givenBy: \Self.aiSetsOffset)
			var aiSets: [Int32]
			
			@Count(givenBy: \Self.vivosaurCount3)
			@Offset(givenBy: \Self.interLevelBattlePointsPerVivosaurOffset)
			var interLevelBattlePointsPerVivosaur: [FixedPoint2012] // percentage between levels
			
			@Count(givenBy: \Self.vivosaurCount4)
			@Offset(givenBy: \Self.movesUnlockedPerVivosaurOffset)
			var movesUnlockedPerVivosaur: [Int32]
			
			@Count(givenBy: \Self.unknowns3Count)
			@Offset(givenBy: \Self.unknowns3Offset)
			var unknowns3: [Int32]
			
			@BinaryConvertible
			struct Vivosaur {
				var id: Int32
				var level: Int32
				var hideStats: UInt32
			}
		}
		
		@BinaryConvertible
		struct Unknown {
			var unknown1: Int32
			var unknown2: Int32
		}
	}
	
	struct Unpacked: Codable {
		var music: Music
		
		var unknown3: Int32
		var unknown4: Int32
		var unknown5: Int32
		var unknown6: Int32
		
		var unknown7: Int32
		var unknown8: Int32
		var announcerDialogue: Int32
		var unknown10: Int32
		
		var arena: Arena
		
		var unknown11: Int32
		var unknown12: Int32
		var unknown13: Int32
		
		var unknown14: Int32
		var bpForWinning: Int32
		var unknown16: Int32
		
		var fighter1: Fighter?
		
		var fighter2: Fighter
		
		var unknowns17: [Unknown]
		
		var requiredVivosaurs: [Fighter.Vivosaur.ID]
		
		struct Arena {
			var id: Int32
		}
		
		struct Music {
			var id: Int32
		}
		
		struct Fighter: Codable {
			var name: Name
			var rank: Int32
			
			var icon: Int32
			var minimumVivosaurHealth: Int32
			
			var vivosaurs: [Vivosaur]
			var unknowns3: [Int32]
			
			struct Name: Codable {
				var _label: String?
				var id: Int32
			}
			
			struct Vivosaur: Codable {
				var id: ID
				var level: Int32
				
				var hideDinoMedal: Bool
				var hideStats: Bool
				
				var aiSet: Int32?
				var interLevelBattlePoints: Double
				var movesUnlocked: Int32
				
				struct ID {
					var id: Int32
				}
			}
		}
		
		struct Unknown: Codable {
			var unknown1: Int32
			var unknown2: Int32
		}
	}
}

// MARK: packed
extension DBS.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) throws -> DBS.Unpacked {
		try DBS.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: DBS.Unpacked, configuration: Configuration) {
		music = unpacked.music.id
		
		unknown3 = unpacked.unknown3
		unknown4 = unpacked.unknown4
		unknown5 = unpacked.unknown5
		unknown6 = unpacked.unknown6
		
		unknown7 = unpacked.unknown7
		unknown8 = unpacked.unknown8
		unknown9 = unpacked.announcerDialogue
		unknown10 = unpacked.unknown10
		
		arena = unpacked.arena.id
		
		unknown11 = unpacked.unknown11
		unknown12 = unpacked.unknown12
		unknown13 = unpacked.unknown13
		
		unknown14 = unpacked.unknown14
		bpForWinning = unpacked.bpForWinning
		unknown16 = unpacked.unknown16
		
		fighter1 = unpacked.fighter1.map(Fighter.init)
		fighter1Offset = fighter1 == nil ? 0 : 0x5c
		
		fighter2 = Fighter(unpacked.fighter2)
		fighter2Offset = 0x5c + (fighter1?.size() ?? 0)
		
		unknowns17 = unpacked.unknowns17.map(Unknown.init)
		unknowns17Count = UInt32(unknowns17.count)
		unknowns17Offset = fighter2Offset + fighter2.size()
		
		requiredVivosaurs = unpacked.requiredVivosaurs.map(\.id)
		requiredVivosaurCount = UInt32(requiredVivosaurs.count)
		requiredVivosaursOffset = unknowns17Offset + unknowns17Count * 8
	}
}

extension DBS.Packed.Fighter {
	init(_ unpacked: DBS.Unpacked.Fighter) {
		name = unpacked.name.id
		rank = unpacked.rank
		
		icon = unpacked.icon
		minimumVivosaurHealth = unpacked.minimumVivosaurHealth
		
		vivosaurs = unpacked.vivosaurs.map(Vivosaur.init)
		vivosaurCount = UInt32(vivosaurs.count)
		
		aiSets = unpacked.vivosaurs.compactMap(\.aiSet)
		vivosaurCount2 = UInt32(aiSets.count)
		aiSetsOffset = vivosaursOffset + vivosaurCount * 0xC
		
		interLevelBattlePointsPerVivosaur = unpacked.vivosaurs
			.map(\.interLevelBattlePoints)
			.map { FixedPoint2012($0) }
		vivosaurCount3 = UInt32(interLevelBattlePointsPerVivosaur.count)
		interLevelBattlePointsPerVivosaurOffset = aiSetsOffset + vivosaurCount2 * 4
		
		movesUnlockedPerVivosaur = unpacked.vivosaurs.map(\.movesUnlocked)
		vivosaurCount4 = UInt32(movesUnlockedPerVivosaur.count)
		movesUnlockedPerVivosaurOffset = interLevelBattlePointsPerVivosaurOffset + vivosaurCount3 * 4
		
		unknowns3 = unpacked.unknowns3
		unknowns3Count = UInt32(unknowns3.count)
		unknowns3Offset = movesUnlockedPerVivosaurOffset + vivosaurCount4 * 4
	}
	
	func size() -> UInt32 {
		unknowns3Offset + unknowns3Count * 4
	}
}

extension DBS.Packed.Fighter.Vivosaur {
	init(_ unpacked: DBS.Unpacked.Fighter.Vivosaur) {
		id = unpacked.id.id
		level = unpacked.level
		hideStats = (unpacked.hideDinoMedal ? 1 : 0) + (unpacked.hideStats ? 0b10 : 0)
	}
}

extension DBS.Packed.Unknown {
	init(_ unpacked: DBS.Unpacked.Unknown) {
		unknown1 = unpacked.unknown1
		unknown2 = unpacked.unknown2
	}
}


// MARK: unpacked
extension DBS.Unpacked: ProprietaryFileData {
	static let fileExtension = ".dbs.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: Configuration) -> DBS.Packed {
		DBS.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: DBS.Packed, configuration: Configuration) throws {
		music = Music(id: packed.music)
		
		unknown3 = packed.unknown3
		unknown4 = packed.unknown4
		unknown5 = packed.unknown5
		unknown6 = packed.unknown6
		
		unknown7 = packed.unknown7
		unknown8 = packed.unknown8
		announcerDialogue = packed.unknown9
		unknown10 = packed.unknown10
		
		arena = Arena(id: packed.arena)
		
		unknown11 = packed.unknown11
		unknown12 = packed.unknown12
		unknown13 = packed.unknown13
		
		unknown14 = packed.unknown14
		bpForWinning = packed.bpForWinning
		unknown16 = packed.unknown16
		
		// nil for 0578
		fighter1 = try packed.fighter1.map { try Fighter($0, configuration: configuration) }
		
		fighter2 = try Fighter(packed.fighter2, configuration: configuration)
		
		unknowns17 = packed.unknowns17.map(Unknown.init)
		
		requiredVivosaurs = packed.requiredVivosaurs.map(Fighter.Vivosaur.ID.init)
	}
}

extension DBS.Unpacked.Fighter {
	struct MismatchedVivosaurCount: Error, CustomStringConvertible {
		var vivosaurCount: Int
		var interLevelBattlePointCount: Int
		var movesUnlockedCount: Int
		
		var description: String {
			"error in binary DBS file: mismatched numbers of vivosaurs, inter-level battle points, and moves unlocked: \(vivosaurCount), \(interLevelBattlePointCount), and \(movesUnlockedCount)"
		}
	}
	
	init(_ packed: DBS.Packed.Fighter, configuration: Configuration) throws {
		name = Name(id: packed.name)
		rank = packed.rank
		
		icon = packed.icon
		minimumVivosaurHealth = packed.minimumVivosaurHealth
		
		guard packed.vivosaurs.count == packed.interLevelBattlePointsPerVivosaur.count,
			  packed.vivosaurs.count == packed.movesUnlockedPerVivosaur.count
		else {
			throw MismatchedVivosaurCount(
				vivosaurCount: packed.vivosaurs.count,
				interLevelBattlePointCount: packed.interLevelBattlePointsPerVivosaur.count,
				movesUnlockedCount: packed.movesUnlockedPerVivosaur.count
			)
		}
		
		vivosaurs = packed.vivosaurs.indices.map { index in
			Vivosaur(
				packed.vivosaurs[index],
				aiSet: packed.aiSets[safely: index],
				interLevelBattlePoints: packed.interLevelBattlePointsPerVivosaur[index],
				movesUnlocked: packed.movesUnlockedPerVivosaur[index]
			)
		}
		
		unknowns3 = packed.unknowns3
	}
}

extension DBS.Unpacked.Fighter.Vivosaur {
	init(
		_ packed: DBS.Packed.Fighter.Vivosaur,
		aiSet: Int32?,
		interLevelBattlePoints: FixedPoint2012,
		movesUnlocked: Int32
	) {
		id = ID(id: packed.id)
		level = packed.level
		
		hideDinoMedal = packed.hideStats & 1 > 0
		hideStats = packed.hideStats & 0b10 > 0
		
		self.aiSet = aiSet
		self.interLevelBattlePoints = Double(interLevelBattlePoints)
		self.movesUnlocked = movesUnlocked
	}
}

extension DBS.Unpacked.Unknown {
	init(_ packed: DBS.Packed.Unknown) {
		unknown1 = packed.unknown1
		unknown2 = packed.unknown2
	}
}

// MARK: unpacked codable
extension DBS.Unpacked {
	enum KeyNotFoundError: Error, CustomStringConvertible {
		case vivosaurNotFound(String)
		case kasekiumNotFound(String)
		case musicNotFound(String)
		case mismatchedType(for: String)
		
		var description: String {
			switch self {
				case .vivosaurNotFound(let name):
					"could not find vivosaur named '\(name)'"
				case .kasekiumNotFound(let name):
					"could not find arena named '\(name)'"
				case .musicNotFound(let name):
					"could not find music named '\(name)'"
				case .mismatchedType(for: let name):
					"unexpected type for \(name): expected number or string"
			}
		}
	}
}

extension DBS.Unpacked.Arena: Codable {
	init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		
		do {
			id = try container.decode(Int32.self)
		} catch {
			let arenaName: String
			do {
				arenaName = try container.decode(String.self)
			} catch {
				throw DBS.Unpacked.KeyNotFoundError.mismatchedType(for: "arena")
			}
			
			guard let kasekiumID = kasekiumIDs[arenaName.lowercased()] else {
				throw DBS.Unpacked.KeyNotFoundError.kasekiumNotFound(arenaName)
			}
			
			id = kasekiumID
		}
	}
	
	func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		
		if let arenaName = kasekiumNames[id] {
			try container.encode(arenaName)
		} else {
			try container.encode(id)
		}
	}
}

extension DBS.Unpacked.Music: Codable {
	init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		
		do {
			id = try container.decode(Int32.self)
		} catch {
			let musicName: String
			do {
				musicName = try container.decode(String.self)
			} catch {
				throw DBS.Unpacked.KeyNotFoundError.mismatchedType(for: "music")
			}
			
			guard let musicID = musicIDs[musicName.lowercased()] else {
				throw DBS.Unpacked.KeyNotFoundError.musicNotFound(musicName)
			}
			
			id = musicID
		}
	}
	
	func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		
		if let musicName = musicNames[id] {
			try container.encode(musicName)
		} else {
			try container.encode(id)
		}
	}
}

extension DBS.Unpacked.Fighter.Vivosaur.ID: Codable {
	init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		
		do {
			id = try container.decode(Int32.self)
		} catch {
			let vivosaurName: String
			do {
				vivosaurName = try container.decode(String.self)
			} catch {
				throw DBS.Unpacked.KeyNotFoundError.mismatchedType(for: "vivosaur")
			}
			
			guard let vivosaurID = vivosaurIDs[vivosaurName.lowercased()] else {
				throw DBS.Unpacked.KeyNotFoundError.vivosaurNotFound(vivosaurName)
			}
			
			id = vivosaurID
		}
	}
	
	func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		
		if let vivosaurName = vivosaurNames[id] {
			try container.encode(vivosaurName)
		} else {
			try container.encode(id)
		}
	}
}
