import BinaryParser

struct MAP {
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "MAP"
		
		var mapNameOffset: UInt32 = 0x6C
		var collisionMapNameOffset: UInt32
		
		var unknown1: Int32
		
		// 0x10
		var unknown2: Int32
		var unknown3: Int32
		var thingACount: UInt32
		var thingAOffset: UInt32
		// 0x20
		var unknown6: Int32
		var unknown7: Int32
		var unknown8: Int32
		var unknown9: Int32 // fixed-point?
		// 0x30
		var unknown10: Int32 // fixed-point?
		var unknown11: Int32 // fixed-point?
		var thingBCount: UInt32
		var thingBOffset: UInt32
		// 0x40
		var thingCCount: UInt32
		var thingCOffset: UInt32
		var thingDCount: UInt32
		var thingDOffset: UInt32
		// 0x50
		var thingECount: UInt32
		var thingEOffsetsOffset: UInt32
		var thingFCount: UInt32
		var thingFOffsetsOffset: UInt32
		// 0x60
		var backgroundGradientTopOffset: UInt32
		var backgroundGradientBottomOffset: UInt32
		var unknown24: UInt32 // unknown
		
		@Offset(givenBy: \Self.mapNameOffset)
		var mapName: String
		
		@Offset(givenBy: \Self.collisionMapNameOffset)
		var collisionMapName: String
		
		@Count(givenBy: \Self.thingACount)
		@Offset(givenBy: \Self.thingAOffset)
		var thingA: [ThingA]
		
		@Count(givenBy: \Self.thingBCount)
		@Offset(givenBy: \Self.thingBOffset)
		var thingB: [ThingB] // smthn with characters?
		
		@Count(givenBy: \Self.thingCCount)
		@Offset(givenBy: \Self.thingCOffset)
		var thingC: [ThingC]
		
		@Count(givenBy: \Self.thingDCount)
		@Offset(givenBy: \Self.thingDOffset)
		var thingD: [ThingD]
		
		@Count(givenBy: \Self.thingECount)
		@Offset(givenBy: \Self.thingEOffsetsOffset)
		var thingEOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.thingEOffsets)
		var thingE: [ThingE]
		
		@Count(givenBy: \Self.thingFCount)
		@Offset(givenBy: \Self.thingFOffsetsOffset)
		var thingFOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.thingFOffsets)
		var thingF: [ThingF]
		
		@Offset(givenBy: \Self.backgroundGradientTopOffset)
		var backgroundGradientTop: Color
		
		@Offset(givenBy: \Self.backgroundGradientBottomOffset)
		var backgroundGradientBottom: Color
		
		@BinaryConvertible
		struct ThingA {
			var unknown1: Int32
			var unknown2: Int32
		}
		
		@BinaryConvertible
		struct ThingB {
			var unknown1: Int32
			var x: Int32
			var y: Int32
			var unknown4: Int32 // fixed point
			var unknown5: Int32 = 0
		}
		
		@BinaryConvertible
		struct ThingC {
			var unknown1: Int16
			var unknown2: Int16
			var unknown3: Int32 // weird? fixed point??
			var unknown4: Int32 // fixed point
		}
		
		@BinaryConvertible
		struct ThingD {
			var unknown1: Int16
			var unknown2: Int16
			
			var unknown3: Int32
			
			var unknown4: Int16
			var unknown5: Int16
			
			var unknown6: Int32
			
			var unknown7: Int16
			var unknown8: Int16
			
			var unknown9: Int32
		}
		
		@BinaryConvertible
		struct ThingE { // fossils
			var unknown1: Int32
			var zone: Int32 // ?
			var sonarUpgrades: Int32 // ?
			var maxSpawns: Int32 // ?
			
			var unknown2: Int32
			var unknown3: Int32
			var thingACount: UInt32
			var thingAOffset: UInt32
			
			var thingBCount: UInt32
			var thingBOffset: UInt32
			var thingCCount: UInt32
			var thingCOffsetsOffset: UInt32
			
			@Count(givenBy: \Self.thingACount)
			@Offset(givenBy: \Self.thingAOffset)
			var thingAs: [Int32]
			
			@Count(givenBy: \Self.thingBCount)
			@Offset(givenBy: \Self.thingBOffset)
			var thingBs: [ThingB]
			
			@Count(givenBy: \Self.thingCCount)
			@Offset(givenBy: \Self.thingCOffsetsOffset)
			var thingCOffsets: [UInt32]
			
			@Offsets(givenBy: \Self.thingCOffsets)
			var thingCs: [ThingC]
			
			@BinaryConvertible
			struct ThingB {
				var unknown1: Int32
				var unknown2: Int32
				var unknown3: Int32
				var unknown4: Int32
				var unknown5: Int32 // these are (at least sometimes) incrementing
				var unknown6: Int32 // these are (at least sometimes) incrementing
				var unknown7: Int32 // these are (at least sometimes) incrementing
				var unknown8: Int32 // these are (at least sometimes) incrementing
				var unknown9: Int32 // these are (at least sometimes) incrementing
				var unknown10: Int32 // these are (at least sometimes) incrementing
				var unknown11: Int32 // these are (at least sometimes) incrementing
				var unknown12: Int32 // these are (at least sometimes) incrementing
			}
			
			@BinaryConvertible
			struct ThingC {
				var unknown1: Int32
				var unknown2: Int32
				var unknown3: Int32
				var unknown4: Int32
				var unknown5: Int32
				var unknown6: Int32
				var unknown7: Int32
				var unknown8: Int32
			}
		}
		
		@BinaryConvertible
		struct ThingF {
			var unknown1: Int32
			var unknown2: Int32
			var unknown3: Int32
			var unknown4: Int32 // fixed-point
			var unknown5: Int32
			var unknown6: Int32
		}
		
		@BinaryConvertible
		struct Color {
			var red: UInt8
			var green: UInt8
			var blue: UInt8
		}
	}
}

extension MAP: ProprietaryFileData, BinaryConvertible, Codable {
	static let fileExtension = ".map.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	init(_ binary: Binary, configuration: CarbonizerConfiguration) {
//		print(binary)
		todo()
	}
}

extension MAP.Binary: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	init(_ MAP: MAP, configuration: CarbonizerConfiguration) {
		todo()
	}
}
