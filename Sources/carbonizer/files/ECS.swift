import BinaryParser

struct ECS {
	var effectNames: [String]
	var imageNames: [String]
	
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "ECS"
		
		var thingACount: UInt32
		var thingAOffsetsOffset: UInt32
		
		// these (until 0x20) may be 16-bit
		var unknown1: Int32
		// 0x10
		var unknown2: Int32
		var unknown3: Int32
		var unknown4: Int32
		var unknown5: Int32
		// 0x20
		var unknown6: Int32
		var unknown7: Int32
		var unknown8: Int32
		
		var thingBCount: UInt32
		var thingBOffset: UInt32
		
		var unknown9: Int32
		
		var thingCCount: UInt32
		var thingCOffsetsOffset: UInt32
		
		// 0x40
		var thingDCount: Int32
		var thingDOffset: UInt32
		var thingECount: Int32
		var thingEOffset: UInt32
		// 0x50
		var thingFCount: Int32
		var thingFOffset: UInt32
		var effectNameCount: Int32
		var effectNameOffsetsOffset: UInt32
		// 0x60
		var imageCount: UInt32
		var imageNamesOffsetsOffset: UInt32
		var thingICount: UInt32
		var thingIOffset: UInt32
		// 0x70
		var thingJCount: UInt32
		var thingJOffset: UInt32
		var thingKOffset: UInt32
		var charactersOffset: UInt32
		// 0x80
		var thingMOffset: UInt32
		var thingNOffset: UInt32
		var thingOCount: UInt32
		var thingOOffset: UInt32
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
		var thingPOffset: UInt32
		var thingQOffset: UInt32
		var donationPointsCount: UInt32
		// 0xc0
		var donationPointsOffset: UInt32
		
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
		
		@Count(givenBy: \Self.thingDCount)
		@Offset(givenBy: \Self.thingDOffset)
		var thingDs: [Int32] // jewel rocks
		
		@Count(givenBy: \Self.thingECount)
		@Offset(givenBy: \Self.thingEOffset)
		var thingEs: [Int32] // dropping rocks
		
		@Count(givenBy: \Self.thingFCount)
		@Offset(givenBy: \Self.thingFOffset)
		var thingFs: [Int32]
		
		@Count(givenBy: \Self.effectNameCount)
		@Offset(givenBy: \Self.effectNameOffsetsOffset)
		var effectNameOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.effectNameOffsets)
		var effectNames: [EffectName]
		
		@Count(givenBy: \Self.imageCount)
		@Offset(givenBy: \Self.imageNamesOffsetsOffset)
		var imageNamesOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.imageNamesOffsets)
		var imageNames: [ImageName]
		
		@Count(givenBy: \Self.thingICount)
		@Offset(givenBy: \Self.thingIOffset)
		var thingIs: [ThingI]
		
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
			 // various sizes...
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
		struct ThingI {
			var index: Int32
			
			var unknown1: Int32
			var unknown2: Int32
			var unknown3: Int32 // fixed point
			var unknown4: Int32 // fixed point
			var unknown5: Int32
			var unknown6: Int32 // fixed point
			var unknown7: Int32 // fixed point
			var unknown8: Int32
			var unknown9: Int32 // fixed point
			var unknown10: Int32 // fixed point
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
			var characterOffset: UInt32
			
			var thingACount: UInt32
			var thingAOffset: UInt32
			
			var unknown1: Int32
			var unknown2: Int32
			var unknown3: Int32
			var unknown4: Int32
			
			@Count(givenBy: \Self.characterCount)
			@Offset(givenBy: \Self.characterOffset)
			var characterOffsets: [UInt32]
			
			@Offsets(givenBy: \Self.characterOffsets)
			var characters: [Character]
			
			@Count(givenBy: \Self.thingACount)
			@Offset(givenBy: \Self.thingAOffset)
			var thingAs: [Int32]
			
			@BinaryConvertible
			struct Character {
				var nameOffset: UInt32 = 0x10
				var color1Offset: UInt32
				var color2Offset: UInt32
				
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
}

extension ECS: ProprietaryFileData, BinaryConvertible, Codable {
	static let fileExtension = ".ecs.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	init(_ binary: Binary, configuration: CarbonizerConfiguration) {
//		print(binary)
		
		effectNames = binary.effectNames.map(\.effectName)
		imageNames = binary.imageNames.map(\.imageName)
	}
}

extension ECS.Binary: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	init(_ ecs: ECS, configuration: CarbonizerConfiguration) {
		todo()
	}
}
