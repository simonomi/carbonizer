import BinaryParser

enum ECS {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "ECS"
		
		var thingACount: UInt32
		var thingAOffsetsOffset: UInt32 = 0xC4
		
		var unknown1: Int32 // fixed-point
		// 0x10
		var unknown2: Int32 // fixed-point
		var unknown3: Int32 // fixed-point
		var unknown4: Int32 // fixed-point
		var unknown5: Int32
		// 0x20
		var unknown6: Int32
		var unknown7: Int32
		var unknown8: Int32
		
		var thingBCount: UInt32
		var thingBOffset: UInt32 = 0x118
		
		var unknown9: Int32
		
		var thingCCount: UInt32
		var thingCOffsetsOffset: UInt32 = 0x124
		
		// 0x40
		var jewelRockIDCount: UInt32
		var jewelRockIDsOffset: UInt32 = 0xCE0
		var droppingRockIDCount: UInt32
		var droppingRockIDsOffset: UInt32 = 0xD58
		// 0x50
		var thingFCount: UInt32
		var thingFOffset: UInt32 = 0xDD0
		var effectNameCount: UInt32
		var effectNameOffsetsOffset: UInt32 = 0xDDC
		// 0x60
		var imageCount: UInt32
		var imageNameOffsetsOffset: UInt32 = 0xF70
		var kl33nLevelCount: UInt32
		var kl33nLevelsOffset: UInt32 = 0x21FC
		// 0x70
		var thingJCount: UInt32
		var thingJOffset: UInt32 = 0x235C
		var thingKOffset: UInt32 = 0x2424
		var charactersOffset: UInt32 = 0x2464
		// 0x80
		var thingMOffset: UInt32 = 0x37E8
		var thingNOffset: UInt32 = 0x3848
		var thingOCount: UInt32
		var thingOOffset: UInt32 = 0x384C
		// 0x90
		var unknown10: Int32
		var unknown11: Int32
		var unknown12: Int32
		var unknown13: Int32
		// 0xa0
		var unknown14: Int32
		var unknown15: Int32
		var unknown16: Int32
		var unknown17: Int32
		// 0xb0
		var thingPCount: UInt32
		var thingPOffset: UInt32 = 0x3C0C
		var thingQOffset: UInt32 = 0x3C18
		var donationPointsCount: UInt32
		// 0xc0
		var donationPointsOffset: UInt32 = 0x3C58
		
		@Count(givenBy: \Self.thingACount)
		@Offset(givenBy: \Self.thingAOffsetsOffset)
		var thingAOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.thingAOffsets)
		var thingAs: [ThingA]
		
		@Count(givenBy: \Self.thingBCount)
		@Offset(givenBy: \Self.thingBOffset)
		var thingBs: [Int32]
		
		@Count(givenBy: \Self.thingCCount)
		@Offset(givenBy: \Self.thingCOffsetsOffset)
		var thingCOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.thingCOffsets)
		var thingCs: [ThingC]
		
		@Count(givenBy: \Self.jewelRockIDCount)
		@Offset(givenBy: \Self.jewelRockIDsOffset)
		var jewelRockIDs: [Int32]
		
		@Count(givenBy: \Self.droppingRockIDCount)
		@Offset(givenBy: \Self.droppingRockIDsOffset)
		var droppingRockIDs: [Int32]
		
		@Count(givenBy: \Self.thingFCount)
		@Offset(givenBy: \Self.thingFOffset)
		var thingFs: [Int32]
		
		@Count(givenBy: \Self.effectNameCount)
		@Offset(givenBy: \Self.effectNameOffsetsOffset)
		var effectNameOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.effectNameOffsets)
		var effectNames: [EffectName]
		
		@Count(givenBy: \Self.imageCount)
		@Offset(givenBy: \Self.imageNameOffsetsOffset)
		var imageNameOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.imageNameOffsets)
		var imageNames: [ImageName]
		
		@Count(givenBy: \Self.kl33nLevelCount)
		@Offset(givenBy: \Self.kl33nLevelsOffset)
		var kl33nLevels: [KL33NLevel]
		
		@Count(givenBy: \Self.thingJCount)
		@Offset(givenBy: \Self.thingJOffset)
		var thingJs: [ThingJ]
		
		@Offset(givenBy: \Self.thingKOffset)
		var thingK: ThingK
		
		@Offset(givenBy: \Self.charactersOffset)
		var characters: Characters
		
		@Offset(givenBy: \Self.thingMOffset)
		var thingM: ThingM
		
		@Offset(givenBy: \Self.thingNOffset)
		var thingN: ThingN
		
		@Count(givenBy: \Self.thingOCount)
		@Offset(givenBy: \Self.thingOOffset)
		var thingOs: [Int32]
		
		@Count(givenBy: \Self.thingPCount)
		@Offset(givenBy: \Self.thingPOffset)
		var thingPs: [Int32]
		
		@Offset(givenBy: \Self.thingQOffset)
		var thingQ: ThingQ
		
		@Count(givenBy: \Self.donationPointsCount)
		@Offset(givenBy: \Self.donationPointsOffset)
		var donationPoints: [DonationPointForScore]
		
		@BinaryConvertible
		struct ThingA {
			var unknown1: Int32
			var unknown2: Int32
			var unknown3: Int32
			var unknown4: Int32
			var unknown5: Int32
			var unknown6: Int32
		}
		
		@BinaryConvertible
		struct ThingC {
			var count: UInt32
			var offset: UInt32 = 0x8
			
			@Count(givenBy: \Self.count)
			@Offset(givenBy: \Self.offset)
			var things: [Int32] // all zero!
		}
		
		@BinaryConvertible
		struct EffectName {
			var effectNameOffset: UInt32 = 4
			
			@Offset(givenBy: \Self.effectNameOffset)
			var effectName: String
		}
		
		@BinaryConvertible
		struct ImageName {
			var imageNameOffset: UInt32 = 4
			
			@Offset(givenBy: \Self.imageNameOffset)
			var imageName: String
		}
		
		@BinaryConvertible
		struct KL33NLevel {
			var level: Int32
			
			// these seem to be counting up? like 0/10 10/30 30/70...
			var requiredFossilsCleaned: Int32
			var nextLevelAt: Int32
			
			var cleaningScoreLowerBound: Int32 // fixed point
			var cleaningScoreUpperBound: Int32 // fixed point
			
			var higherScoreProbability: Int32 // fixed point
			
			var higherScoreLowerBound: Int32 // fixed point
			var higherScoreUpperBound: Int32 // fixed point
			
			var otherScoreProbability: Int32  // fixed point? always 0
			var otherScoreLowerBound: Int32 // fixed point
			var otherScoreUpperBound: Int32 // fixed point
		}
		
		@BinaryConvertible
		struct ThingJ {
			var index: Int32
			var unknown: Int32
		}
		
		@BinaryConvertible
		struct ThingK {
			@Count(16)
			var unknowns: [UInt32] // fixed-point
		}
		
		@BinaryConvertible
		struct Characters {
			var characterCount: UInt32
			var characterOffset: UInt32 = 0x24
			
			var thingACount: UInt32
			var thingAOffset: UInt32 = 0x1378
			
			var unknown1: Int32 // fixed-point
			var unknown2: Int32 // fixed-point
			var unknown3: Int32 // fixed-point
			var unknown4: Int32
			var unknown5: Int32
			
			@Count(givenBy: \Self.characterCount)
			@Offset(givenBy: \Self.characterOffset)
			var characterOffsets: [UInt32]
			
			@Offsets(givenBy: \Self.characterOffsets)
			var characters: [Character]
			
			@Count(givenBy: \Self.thingACount)
			@Offset(givenBy: \Self.thingAOffset)
			var thingAs: [Int32] // fixed-point
			
			@BinaryConvertible
			struct Character {
				var nameOffset: UInt32 = 0x10
				var color1Offset: UInt32
				var color2Offset: UInt32
				var dialogueSound: Int32 // 170: boy
										 // 171: girl
										 // 172: dinaurian
										 // 173: unused
										 // 174: other
										 // 913: KL-33N
				
				@Offset(givenBy: \Self.nameOffset)
				var name: String
				
				@Count(3)
				@Offset(givenBy: \Self.color1Offset)
				var color1: [UInt8]
				
				@Count(3)
				@Offset(givenBy: \Self.color2Offset)
				var color2: [UInt8]
			}
		}
		
		@BinaryConvertible
		struct ThingM {
			@Count(24)
			var unknowns: [Int32]
		}
		
		@BinaryConvertible
		struct ThingN {
			var unknown1: UInt16
			var unknown2: UInt16
		}
		
		@BinaryConvertible
		struct ThingQ {
			@Count(16)
			var unknowns: [Int32]
		}
		
		@BinaryConvertible
		struct DonationPointForScore {
			var lowerBound: Int32
			var upperBound: Int32 // inclusive
			var donationPoints: Int32
		}
	}
	
	struct Unpacked: Codable {
		var unknown1: Double
		var unknown2: Double
		var unknown3: Double
		var unknown4: Double
		var unknown5: Int32
		var unknown6: Int32
		var unknown7: Int32
		var unknown8: Int32
		
		var unknown9: Int32
		
		var unknown10: Double
		var unknown11: Double
		var unknown12: Int32
		var unknown13: Int32
		var unknown14: Int32
		var unknown15: Int32
		var unknown16: Int32
		var unknown17: Int32
		
		var thingAOffsets: [UInt32]
		
		var thingAs: [ThingA]
		
		var thingBs: [Int32]
		
		var thingCOffsets: [UInt32]
		
		var thingCs: [ThingC]
		
		var jewelRockIDs: [Int32]
		
		var droppingRockIDs: [Int32]
		
		var thingFs: [Int32]
		
		var effectNameOffsets: [UInt32]
		
		var effectNames: [EffectName]
		
		var imageNameOffsets: [UInt32]
		
		var imageNames: [ImageName]
		
		var kl33nLevels: [KL33NLevel]
		
		var thingJs: [ThingJ]
		
		var thingK: ThingK
		
		var characters: Characters
		
		var thingM: ThingM
		
		var thingN: ThingN
		
		var thingOs: [Int32]
		
		var thingPs: [Int32]
		
		var thingQ: ThingQ
		
		var donationPoints: [DonationPointForScore]
		
		struct ThingA: Codable {
			var unknown1: Int32
			var unknown2: Int32
			var unknown3: Int32
			var unknown4: Int32
			var unknown5: Int32
			var unknown6: Int32
		}
		
		struct ThingC: Codable {
			var things: [Int32]
		}
		
		struct EffectName {
			var effectName: String
		}
		
		struct ImageName {
			var imageName: String
		}
		
		struct KL33NLevel: Codable {
			var level: Int32
			
			var requiredFossilsCleaned: Int32
			var nextLevelAt: Int32
			
			var cleaningScoreLowerBound: Double
			var cleaningScoreUpperBound: Double // not included
			
			var higherScoreProbability: Double
			
			var higherScoreLowerBound: Double
			var higherScoreUpperBound: Double // not included
			
			var otherScoreProbability: Double // uses the same random number as higher score, so
											  // setting them both to 50% always overrides default score
											  // but higher score gets prioirity, so both 100% chooses higher
			var otherScoreLowerBound: Double
			var otherScoreUpperBound: Double
		}
		
		struct ThingJ: Codable {
			var index: Int32
			var unknown: Int32
		}
		
		struct ThingK: Codable {
			var unknowns: [UInt32]
		}
		
		struct Characters: Codable {
			var unknown1: Double
			var unknown2: Double
			var unknown3: Double
			var unknown4: Int32
			var unknown5: Int32
			
			var characterOffsets: [UInt32]
			
			var characters: [Character]
			
			var thingAs: [Double]
			
			struct Character: Codable {
				var name: String
				var color1: Color
				var color2: Color
				var dialogueSound: Int32
			}
		}
		
		struct ThingM: Codable {
			var unknowns: [Int32]
		}
		
		struct ThingN: Codable {
			var unknown1: UInt16
			var unknown2: UInt16
		}
		
		struct ThingQ: Codable {
			var unknowns: [Int32]
		}
		
		struct DonationPointForScore: Codable {
			var lowerBound: Int32
			var upperBound: Int32
			var donationPoints: Int32
		}
	}
}

// MARK: packed
extension ECS.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> ECS.Unpacked {
		ECS.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: ECS.Unpacked, configuration: CarbonizerConfiguration) {
		thingACount = UInt32(unpacked.thingAs.count)
		
		unknown1 = Int32(fixedPoint: unpacked.unknown1)
		unknown2 = Int32(fixedPoint: unpacked.unknown2)
		unknown3 = Int32(fixedPoint: unpacked.unknown3)
		unknown4 = Int32(fixedPoint: unpacked.unknown4)
		unknown5 = unpacked.unknown5
		unknown6 = unpacked.unknown6
		unknown7 = unpacked.unknown7
		unknown8 = unpacked.unknown8
		
		thingBCount = UInt32(unpacked.thingBs.count)
		
		unknown9 = unpacked.unknown9
		
		thingCCount = UInt32(unpacked.thingCs.count)
		jewelRockIDCount = UInt32(unpacked.jewelRockIDs.count)
		droppingRockIDCount = UInt32(unpacked.droppingRockIDs.count)
		thingFCount = UInt32(unpacked.thingFs.count)
		effectNameCount = UInt32(unpacked.effectNames.count)
		imageCount = UInt32(unpacked.imageNames.count)
		kl33nLevelCount = UInt32(unpacked.kl33nLevels.count)
		thingJCount = UInt32(unpacked.thingJs.count)
		thingOCount = UInt32(unpacked.thingOs.count)
		
		unknown10 = Int32(fixedPoint: unpacked.unknown10)
		unknown11 = Int32(fixedPoint: unpacked.unknown11)
		unknown12 = unpacked.unknown12
		unknown13 = unpacked.unknown13
		unknown14 = unpacked.unknown14
		unknown15 = unpacked.unknown15
		unknown16 = unpacked.unknown16
		unknown17 = unpacked.unknown17
		thingPCount = UInt32(unpacked.thingPs.count)
		donationPointsCount = UInt32(unpacked.donationPoints.count)
		
		thingAOffsets = unpacked.thingAOffsets
		
		thingAs = unpacked.thingAs.map(ThingA.init)
		
		thingBs = unpacked.thingBs
		
		thingCOffsets = unpacked.thingCOffsets
		
		thingCs = unpacked.thingCs.map(ThingC.init)
		
		jewelRockIDs = unpacked.jewelRockIDs
		
		droppingRockIDs = unpacked.droppingRockIDs
		
		thingFs = unpacked.thingFs
		
		effectNameOffsets = unpacked.effectNameOffsets
		
		effectNames = unpacked.effectNames.map(EffectName.init)
		
		imageNameOffsets = unpacked.imageNameOffsets
		
		imageNames = unpacked.imageNames.map(ImageName.init)
		
		kl33nLevels = unpacked.kl33nLevels.map(KL33NLevel.init)
		
		thingJs = unpacked.thingJs.map(ThingJ.init)
		
		thingK = ThingK(unpacked.thingK)
		
		characters = Characters(unpacked.characters)
		
		thingM = ThingM(unpacked.thingM)
		
		thingN = ThingN(unpacked.thingN)
		
		thingOs = unpacked.thingOs
		
		thingPs = unpacked.thingPs
		
		thingQ = ThingQ(unpacked.thingQ)
		
		donationPoints = unpacked.donationPoints.map(DonationPointForScore.init)
	}
}

extension ECS.Packed.ThingA {
	init(_ unpacked: ECS.Unpacked.ThingA) {
		unknown1 = unpacked.unknown1
		unknown2 = unpacked.unknown2
		unknown3 = unpacked.unknown3
		unknown4 = unpacked.unknown4
		unknown5 = unpacked.unknown5
		unknown6 = unpacked.unknown6
	}
}

extension ECS.Packed.ThingC {
	init(_ unpacked: ECS.Unpacked.ThingC) {
		count = UInt32(unpacked.things.count)
		things = unpacked.things
	}
}

extension ECS.Packed.EffectName {
	init(_ unpacked: ECS.Unpacked.EffectName) {
		effectName = unpacked.effectName
	}
}

extension ECS.Packed.ImageName {
	init(_ unpacked: ECS.Unpacked.ImageName) {
		imageName = unpacked.imageName
	}
}

extension ECS.Packed.KL33NLevel {
	init(_ unpacked: ECS.Unpacked.KL33NLevel) {
		level = unpacked.level
		
		requiredFossilsCleaned = unpacked.requiredFossilsCleaned
		nextLevelAt = unpacked.nextLevelAt
		
		cleaningScoreLowerBound = Int32(fixedPoint: unpacked.cleaningScoreLowerBound)
		cleaningScoreUpperBound = Int32(fixedPoint: unpacked.cleaningScoreUpperBound)
		
		higherScoreProbability = Int32(fixedPoint: unpacked.higherScoreProbability)
		
		higherScoreLowerBound = Int32(fixedPoint: unpacked.higherScoreLowerBound)
		higherScoreUpperBound = Int32(fixedPoint: unpacked.higherScoreUpperBound)
		
		otherScoreProbability = Int32(fixedPoint: unpacked.otherScoreProbability)
		otherScoreLowerBound = Int32(fixedPoint: unpacked.otherScoreLowerBound)
		otherScoreUpperBound = Int32(fixedPoint: unpacked.otherScoreUpperBound)
	}
}

extension ECS.Packed.ThingJ {
	init(_ unpacked: ECS.Unpacked.ThingJ) {
		index = unpacked.index
		unknown = unpacked.unknown
	}
}

extension ECS.Packed.ThingK {
	init(_ unpacked: ECS.Unpacked.ThingK) {
		unknowns = unpacked.unknowns
	}
}

extension ECS.Packed.Characters {
	init(_ unpacked: ECS.Unpacked.Characters) {
		unknown1 = Int32(fixedPoint: unpacked.unknown1)
		unknown2 = Int32(fixedPoint: unpacked.unknown2)
		unknown3 = Int32(fixedPoint: unpacked.unknown3)
		unknown4 = unpacked.unknown4
		unknown5 = unpacked.unknown5
		
		characterOffsets = unpacked.characterOffsets
		
		characterCount = UInt32(unpacked.characters.count)
		characters = unpacked.characters.map(Character.init)
		
		thingACount = UInt32(unpacked.thingAs.count)
		thingAs = unpacked.thingAs.map { Int32(fixedPoint: $0) }
	}
}

extension ECS.Packed.Characters.Character {
	init(_ unpacked: ECS.Unpacked.Characters.Character) {
		name = unpacked.name
		color1 = unpacked.color1.bytes
		color2 = unpacked.color2.bytes
		dialogueSound = unpacked.dialogueSound
		
		color1Offset = nameOffset + UInt32(name.utf8CString.count.roundedUpToTheNearest(4))
		color2Offset = color1Offset + 4
	}
}

extension ECS.Packed.ThingM {
	init(_ unpacked: ECS.Unpacked.ThingM) {
		unknowns = unpacked.unknowns
	}
}

extension ECS.Packed.ThingN {
	init(_ unpacked: ECS.Unpacked.ThingN) {
		unknown1 = unpacked.unknown1
		unknown2 = unpacked.unknown2
	}
}

extension ECS.Packed.ThingQ {
	init(_ unpacked: ECS.Unpacked.ThingQ) {
		unknowns = unpacked.unknowns
	}
}

extension ECS.Packed.DonationPointForScore {
	init(_ unpacked: ECS.Unpacked.DonationPointForScore) {
		lowerBound = unpacked.lowerBound
		upperBound = unpacked.upperBound
		donationPoints = unpacked.donationPoints
	}
}

// MARK: unpacked
extension ECS.Unpacked: ProprietaryFileData {
	static let fileExtension = ".ecs.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> ECS.Packed {
		ECS.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: ECS.Packed, configuration: CarbonizerConfiguration) {
		unknown1 = Double(fixedPoint: packed.unknown1)
		unknown2 = Double(fixedPoint: packed.unknown2)
		unknown3 = Double(fixedPoint: packed.unknown3)
		unknown4 = Double(fixedPoint: packed.unknown4)
		unknown5 = packed.unknown5
		unknown6 = packed.unknown6
		unknown7 = packed.unknown7
		unknown8 = packed.unknown8
		
		unknown9 = packed.unknown9
		
		unknown10 = Double(fixedPoint: packed.unknown10)
		unknown11 = Double(fixedPoint: packed.unknown11)
		unknown12 = packed.unknown12
		unknown13 = packed.unknown13
		unknown14 = packed.unknown14
		unknown15 = packed.unknown15
		unknown16 = packed.unknown16
		unknown17 = packed.unknown17
		
		thingAOffsets = packed.thingAOffsets
		
		thingAs = packed.thingAs.map(ThingA.init)
		
		thingBs = packed.thingBs
		
		thingCOffsets = packed.thingCOffsets
		
		thingCs = packed.thingCs.map(ThingC.init)
		
		jewelRockIDs = packed.jewelRockIDs
		
		droppingRockIDs = packed.droppingRockIDs
		
		thingFs = packed.thingFs
		
		effectNameOffsets = packed.effectNameOffsets
		
		effectNames = packed.effectNames.map(EffectName.init)
		
		imageNameOffsets = packed.imageNameOffsets
		
		imageNames = packed.imageNames.map(ImageName.init)
		
		kl33nLevels = packed.kl33nLevels.map(KL33NLevel.init)
		
		thingJs = packed.thingJs.map(ThingJ.init)
		
		thingK = ThingK(packed.thingK)
		
		characters = Characters(packed.characters)
		
		thingM = ThingM(packed.thingM)
		
		thingN = ThingN(packed.thingN)
		
		thingOs = packed.thingOs
		
		thingPs = packed.thingPs
		
		thingQ = ThingQ(packed.thingQ)
		
		donationPoints = packed.donationPoints.map(DonationPointForScore.init)
	}
}

extension ECS.Unpacked.ThingA {
	init(_ packed: ECS.Packed.ThingA) {
		unknown1 = packed.unknown1
		unknown2 = packed.unknown2
		unknown3 = packed.unknown3
		unknown4 = packed.unknown4
		unknown5 = packed.unknown5
		unknown6 = packed.unknown6
	}
}

extension ECS.Unpacked.ThingC {
	init(_ packed: ECS.Packed.ThingC) {
		things = packed.things
	}
}

extension ECS.Unpacked.EffectName: Codable {
	init(_ packed: ECS.Packed.EffectName) {
		effectName = packed.effectName
	}
	
	init(from decoder: any Decoder) throws {
		effectName = try String(from: decoder)
	}
	
	func encode(to encoder: any Encoder) throws {
		try effectName.encode(to: encoder)
	}
}

extension ECS.Unpacked.ImageName: Codable {
	init(_ packed: ECS.Packed.ImageName) {
		imageName = packed.imageName
	}
	
	init(from decoder: any Decoder) throws {
		imageName = try String(from: decoder)
	}
	
	func encode(to encoder: any Encoder) throws {
		try imageName.encode(to: encoder)
	}
}

extension ECS.Unpacked.KL33NLevel {
	init(_ packed: ECS.Packed.KL33NLevel) {
		level = packed.level
		
		requiredFossilsCleaned = packed.requiredFossilsCleaned
		nextLevelAt = packed.nextLevelAt
		
		cleaningScoreLowerBound = Double(fixedPoint: packed.cleaningScoreLowerBound)
		cleaningScoreUpperBound = Double(fixedPoint: packed.cleaningScoreUpperBound)
		
		higherScoreProbability = Double(fixedPoint: packed.higherScoreProbability)
		higherScoreLowerBound = Double(fixedPoint: packed.higherScoreLowerBound)
		higherScoreUpperBound = Double(fixedPoint: packed.higherScoreUpperBound)
		
		otherScoreProbability = Double(fixedPoint: packed.otherScoreProbability)
		otherScoreLowerBound = Double(fixedPoint: packed.otherScoreLowerBound)
		otherScoreUpperBound = Double(fixedPoint: packed.otherScoreUpperBound)
	}
}

extension ECS.Unpacked.ThingJ {
	init(_ packed: ECS.Packed.ThingJ) {
		index = packed.index
		unknown = packed.unknown
	}
}

extension ECS.Unpacked.ThingK {
	init(_ packed: ECS.Packed.ThingK) {
		unknowns = packed.unknowns
	}
}

extension ECS.Unpacked.Characters {
	init(_ packed: ECS.Packed.Characters) {
		unknown1 = Double(fixedPoint: packed.unknown1)
		unknown2 = Double(fixedPoint: packed.unknown2)
		unknown3 = Double(fixedPoint: packed.unknown3)
		unknown4 = packed.unknown4
		unknown5 = packed.unknown5
		
		characterOffsets = packed.characterOffsets
		
		characters = packed.characters.map(Character.init)
		
		thingAs = packed.thingAs.map { Double(fixedPoint: $0) }
	}
}

extension ECS.Unpacked.Characters.Character {
	init(_ packed: ECS.Packed.Characters.Character) {
		name = packed.name
		color1 = Color(packed.color1)
		color2 = Color(packed.color2)
		dialogueSound = packed.dialogueSound
	}
}

extension ECS.Unpacked.ThingM {
	init(_ packed: ECS.Packed.ThingM) {
		unknowns = packed.unknowns
	}
}

extension ECS.Unpacked.ThingN {
	init(_ packed: ECS.Packed.ThingN) {
		unknown1 = packed.unknown1
		unknown2 = packed.unknown2
	}
}

extension ECS.Unpacked.ThingQ {
	init(_ packed: ECS.Packed.ThingQ) {
		unknowns = packed.unknowns
	}
}

extension ECS.Unpacked.DonationPointForScore {
	init(_ packed: ECS.Packed.DonationPointForScore) {
		lowerBound = packed.lowerBound
		upperBound = packed.upperBound
		donationPoints = packed.donationPoints
	}
}
