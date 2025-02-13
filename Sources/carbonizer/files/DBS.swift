import BinaryParser

// https://github.com/opiter09/Fossil-Fighters-Documentation/blob/main/FF1/Battle%20Folder.txt
struct DBS {
	var music: Music
	
	var unknown3: Int32
	var unknown4: Int32
	var unknown5: Int32
	var unknown6: Int32
	
	var unknown7: Int32
	var unknown8: Int32
	var unknown9: Int32
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
	
	var requiredVivosaurs: [Int32]
	
	struct Arena {
		var id: Int32
	}
	
	struct Music {
		var id: Int32
	}
	
	struct Fighter: Codable {
		var name: Name
		var rank: Int32
		
		var unknown1: Int32
		var unknown2: Int32
		
		var vivosaurs: [Vivosaur]
		var unknowns3: [Int32]
		
		// TODO: look up name in dtx to create labels (see rls)
		struct Name: Codable {
			var _label: String?
			var id: Int32
		}
		
		struct Vivosaur: Codable {
			var id: ID
			var level: Int32
			var unknown: Int32
			
			var aiSet: Int32
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
	
	@BinaryConvertible
	struct Binary {
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
			var vivosaursOffset: UInt32
			
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
			
			var unknown1: Int32
			var unknown2: Int32 // nonzero in 0401
			
			@Count(givenBy: \Self.vivosaurCount)
			@Offset(givenBy: \Self.vivosaursOffset)
			var vivosaurs: [Vivosaur]
			
			@Count(givenBy: \Self.vivosaurCount2)
			@Offset(givenBy: \Self.aiSetsOffset)
			var aiSets: [Int32]
			
			@Count(givenBy: \Self.vivosaurCount3)
			@Offset(givenBy: \Self.interLevelBattlePointsPerVivosaurOffset)
			var interLevelBattlePointsPerVivosaur: [UInt32] // fixed-point, percentage between levels
			
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
				var unknown: Int32
			}
		}
		
		@BinaryConvertible
		struct Unknown {
			var unknown1: Int32
			var unknown2: Int32
		}
	}
}

extension DBS: ProprietaryFileData, BinaryConvertible, Codable {
	static let fileExtension = ".dbs.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	init(_ binary: Binary, configuration: CarbonizerConfiguration) {
		music = Music(id: binary.music)
		
		unknown3 = binary.unknown3
		unknown4 = binary.unknown4
		unknown5 = binary.unknown5
		unknown6 = binary.unknown6
		
		unknown7 = binary.unknown7
		unknown8 = binary.unknown8
		unknown9 = binary.unknown9
		unknown10 = binary.unknown10
		
		arena = Arena(id: binary.arena)
		
		unknown11 = binary.unknown11
		unknown12 = binary.unknown12
		unknown13 = binary.unknown13
		
		unknown14 = binary.unknown14
		bpForWinning = binary.bpForWinning
		unknown16 = binary.unknown16
		
		fighter2 = Fighter(binary.fighter2)
		
		unknowns17 = binary.unknowns17.map(Unknown.init)
		
		requiredVivosaurs = binary.requiredVivosaurs
	}
}

extension DBS.Arena: Codable {
	init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		
		do {
			id = try container.decode(Int32.self)
		} catch {
			let arenaName = try container.decode(String.self)
			
			guard let foundEntry = kasekiumNames.first(where: { $0.value == arenaName }) else {
				todo("could not find arena named '\(arenaName)'")
			}
			
			id = foundEntry.key
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

extension DBS.Music: Codable {
	init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		
		do {
			id = try container.decode(Int32.self)
		} catch {
			let musicName = try container.decode(String.self)
			
			guard let foundEntry = musicNames.first(where: { $0.value == musicName }) else {
				todo("could not find music named '\(musicName)'")
			}
			
			id = foundEntry.key
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

extension DBS.Fighter {
	init(_ binary: DBS.Binary.Fighter) {
		name = Name(id: binary.name)
		rank = binary.rank
		
		unknown1 = binary.unknown1
		unknown2 = binary.unknown2
		
		guard binary.vivosaurs.count == binary.aiSets.count,
			  binary.vivosaurs.count == binary.interLevelBattlePointsPerVivosaur.count,
			  binary.vivosaurs.count == binary.movesUnlockedPerVivosaur.count
		else {
			todo("wrong number of things, print good error")
		}
		
		vivosaurs = zip(binary.vivosaurs, binary.aiSets, binary.interLevelBattlePointsPerVivosaur, binary.movesUnlockedPerVivosaur)
			.map(Vivosaur.init)
		
		unknowns3 = binary.unknowns3
	}
}

extension DBS.Fighter.Vivosaur { // TODO: vivosaur names
	init(
		_ vivosaur: DBS.Binary.Fighter.Vivosaur,
		aiSet: Int32,
		interLevelBattlePoints: UInt32,
		movesUnlocked: Int32
	) {
		id = ID(id: vivosaur.id)
		level = vivosaur.level
		unknown = vivosaur.unknown
		
		self.aiSet = aiSet
		self.interLevelBattlePoints = Double(interLevelBattlePoints) / 4096
		self.movesUnlocked = movesUnlocked
	}
}

extension DBS.Fighter.Vivosaur.ID: Codable {
	init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		
		do {
			id = try container.decode(Int32.self)
		} catch {
			let vivosaurName = try container.decode(String.self)
			
			guard let foundEntry = vivosaurNames.first(where: { $0.value == vivosaurName }) else {
				todo("could not find vivosaur named '\(vivosaurName)'")
			}
			
			id = foundEntry.key
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

extension DBS.Unknown {
	init(_ binary: DBS.Binary.Unknown) {
		unknown1 = binary.unknown1
		unknown2 = binary.unknown2
	}
}

extension DBS.Binary: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	init(_ dbs: DBS, configuration: CarbonizerConfiguration) {
		todo()
	}
}
