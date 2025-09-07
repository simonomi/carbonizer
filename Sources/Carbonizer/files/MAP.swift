import BinaryParser

enum MAP {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "MAP"
		
		var mapNameOffset: UInt32 = 0x6C
		var collisionMapNameOffset: UInt32
		
		var unknown01: Int32
		
		// 0x10
		var unknown02: Int32
		var unknown03: Int32
		
		var thingACount: UInt32
		var thingAOffset: UInt32
		
		// 0x20
		var unknown06: Int32
		var unknown07: Int32
		var unknown08: Int32
		var unknown09: Int32 // fixed-point
		
		// 0x30
		var unknown10: Int32 // fixed-point
		var bannerTextID: UInt32
		
		var loadingZoneCount: UInt32
		var loadingZonesOffset: UInt32
		
		// 0x40
		var cameraPositionCount: UInt32
		var cameraPositionsOffset: UInt32
		
		var thingDCount: UInt32
		var thingDOffsetsOffset: UInt32
		
		// 0x50
		var fossilSpawnCount: UInt32
		var fossilSpawnOffsetsOffset: UInt32
		
		var breakableRockCount: UInt32
		var breakableRockOffsetsOffset: UInt32
		
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
		
		@Count(givenBy: \Self.loadingZoneCount)
		@Offset(givenBy: \Self.loadingZonesOffset)
		var loadingZones: [LoadingZone]
		
		@Count(givenBy: \Self.cameraPositionCount)
		@Offset(givenBy: \Self.cameraPositionsOffset)
		var cameraPositions: [CameraPosition]
		
		@Count(givenBy: \Self.thingDCount)
		@Offset(givenBy: \Self.thingDOffsetsOffset)
		var thingDOffsets: [UInt32]
		
		@Count(givenBy: \Self.thingDCount)
		@Offsets(givenBy: \Self.thingDOffsets)
		var thingD: [ThingD]
		
		@Count(givenBy: \Self.fossilSpawnCount)
		@Offset(givenBy: \Self.fossilSpawnOffsetsOffset)
		var fossilSpawnOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.fossilSpawnOffsets)
		var fossilSpawns: [FossilSpawn]
		
		@Count(givenBy: \Self.breakableRockCount)
		@Offset(givenBy: \Self.breakableRockOffsetsOffset)
		var breakableRockOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.breakableRockOffsets)
		var breakableRocks: [BreakableRock]
		
		@Count(3)
		@Offset(givenBy: \Self.backgroundGradientTopOffset)
		var backgroundGradientTop: [UInt8]
		
		@Count(3)
		@Offset(givenBy: \Self.backgroundGradientBottomOffset)
		var backgroundGradientBottom: [UInt8]
		
		@FourByteAlign
		var fourByteAlign: ()
		
		@BinaryConvertible
		struct ThingA {
			var topScreenImage: Int32 // 1-fighter, 2-park, 3-guild
			var unknown2: Int32 // setting to 1 crashes
		}
		
		@BinaryConvertible
		struct LoadingZone { // map/r
			var id: Int32
			
			// what do x and y do??? what abt the grd file?
			// they seem to match up with their location, but changing them does... nothing???
			var x: Int32
			var y: Int32
			
			var rotation: Int32 // fixed-point 16.16
			// angle but not degrees again
			// - rotating a door makes the player walk out sideways
			
			var unknown5: Int32 = 0
		}
		
		@BinaryConvertible
		struct CameraPosition: Equatable {
			// first one effects the camera when walking around, no clue abt the rest (not sub areas, not map/c)
			var fov: Int16 // fixed-point 12.4
			var verticalAngle: Int16 // fixed-point 8.8
			var horizontalAngle: Int32 // fixed-point
			var distance: Int32 // fixed point
			
			init(fov: Int16, verticalAngle: Int16, horizontalAngle: Int32, distance: Int32) {
				self.fov = fov
				self.verticalAngle = verticalAngle
				self.horizontalAngle = horizontalAngle
				self.distance = distance
			}
		}
		
		@BinaryConvertible
		struct ThingD { // camera (map/c)
			var cameraPositionOffset: Int32
			
			// different units from LoadingZone's
			var x: Int32
			var y: Int32
			
			var unknown4: Int32
			var unknown5: Int32
			
			@If(\Self.cameraPositionOffset, is: .notEqualTo(0))
			@Offset(givenBy: \Self.cameraPositionOffset)
			var cameraPosition: MAP.Packed.CameraPosition?
		}
		
		@BinaryConvertible
		struct FossilSpawn { // map/e
			var unknown1: Int32
			var zone: Int32
			var sonarUpgrades: Int32 // idk the type for this
			var maxSpawns: Int32
			
			var unknown2: Int32
			var unknown3: Int32
			var thingACount: UInt32
			var thingAOffset: UInt32 = 0x30
			
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
				var unknown01: Int32
				var unknown02: Int32
				var unknown03: Int32
				var unknown04: Int32
				var unknown05: Int32 // these are (at least sometimes) incrementing
				var unknown06: Int32 // these are (at least sometimes) incrementing
				var unknown07: Int32 // these are (at least sometimes) incrementing
				var unknown08: Int32 // these are (at least sometimes) incrementing
				var unknown09: Int32 // these are (at least sometimes) incrementing
				var unknown10: Int32 // these are (at least sometimes) incrementing
				var unknown11: Int32 // these are (at least sometimes) incrementing
				var unknown12: Int32 // these are (at least sometimes) incrementing
			}
			
			@BinaryConvertible
			struct ThingC {
				var vivosaurID: Int32
				
				var unknown2: Int32
				var unknown3: Int32
				var unknown4: Int32
				
				// head/body/arms/legs, but differ by file?
				var fossil1Chance: Int32 // out of 100
				var fossil2Chance: Int32 // out of 100
				var fossil3Chance: Int32 // out of 100
				var fossil4Chance: Int32 // out of 100
			}
		}
		
		@BinaryConvertible
		struct BreakableRock { // map/g
			var unknown1: Int32
			var spawnCount: Int32
			var entityID: Int32
			var rotation: Int32 // fixed-point 16.16
			// not degrees
			// 0 is right
			// 0.25 is down
			// 0.5 is left
			// 0.75 is up
			
			var count: UInt32
			var offset: UInt32 = 0x18
			
			@Count(givenBy: \Self.count)
			@Offset(givenBy: \Self.offset)
			var things: [Thing]
			
			@BinaryConvertible
			struct Thing {
				var unknown1: Int32
				var unknown2: Int32
			}
		}
	}
	
	struct Unpacked: Codable {
		var unknown01: Int32
		
		var unknown02: Int32
		var unknown03: Int32
		
		var unknown06: Int32
		var unknown07: Int32
		var unknown08: Int32
		
		var unknown09: Double
		var unknown10: Double
		
		var bannerTextID: UInt32
		var _name: String?
		
		var unknown24: UInt32 // unknown
		
		var mapName: String
		
		var collisionMapName: String
		
		var thingA: [ThingA]
		
		var loadingZones: [LoadingZone]
		
		var cameraPositions: [CameraPosition]
		
		var thingD: [ThingD]
		
		var fossilSpawns: [FossilSpawn]
		
		var breakableRocks: [BreakableRock]
		
		var backgroundGradientTop: Color
		
		var backgroundGradientBottom: Color
		
		struct ThingA: Codable {
			var topScreenImage: Int32
			var unknown2: Int32
		}
		
		struct LoadingZone: Codable {
			var id: Int32
			var x: Int32
			var y: Int32
			var rotation: Double
		}
		
		struct CameraPosition: Codable {
			var fov: Double
			var verticalAngle: Double
			var horizontalAngle: Double
			var distance: Double
		}
		
		struct ThingD: Codable {
			var unknown2: Int32
			var unknown3: Int32
			var unknown4: Int32
			var unknown5: Int32
			
			var cameraPositon: MAP.Unpacked.CameraPosition?
		}
		
		struct FossilSpawn: Codable {
			var unknown1: Int32
			var zone: Int32
			var sonarUpgrades: Int32
			var maxSpawns: Int32
			
			var unknown2: Int32
			var unknown3: Int32
			
			var thingAs: [Int32]
			
			var thingBs: [ThingB]
			
			var thingCs: [ThingC]
			
			struct ThingB: Codable {
				var unknown01: Int32
				var unknown02: Int32
				var unknown03: Int32
				var unknown04: Int32
				var unknown05: Int32
				var unknown06: Int32
				var unknown07: Int32
				var unknown08: Int32
				var unknown09: Int32
				var unknown10: Int32
				var unknown11: Int32
				var unknown12: Int32
			}
			
			struct ThingC: Codable {
				var vivosaurID: Int32
				var _vivosaur: String?
				
				var unknown2: Int32
				var unknown3: Int32
				var unknown4: Int32
				
				var fossil1Chance: Int32
				var fossil2Chance: Int32
				var fossil3Chance: Int32
				var fossil4Chance: Int32
			}
		}
		
		struct BreakableRock: Codable {
			var unknown1: Int32
			var spawnCount: Int32
			
			var entityID: Int32
			var _entity: String?
			
			var rotation: Double
			
			var things: [Thing]
			
			struct Thing: Codable {
				var unknown1: Int32
				var unknown2: Int32
			}
		}
	}
}

// MARK: packed
extension MAP.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> MAP.Unpacked {
		MAP.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: MAP.Unpacked, configuration: CarbonizerConfiguration) {
		collisionMapNameOffset = mapNameOffset + UInt32(unpacked.mapName.utf8CString.count.roundedUpToTheNearest(4))
		
		unknown01 = unpacked.unknown01
		
		unknown02 = unpacked.unknown02
		unknown03 = unpacked.unknown03
		
		thingACount = UInt32(unpacked.thingA.count)
		thingAOffset = collisionMapNameOffset + UInt32(unpacked.collisionMapName.utf8CString.count.roundedUpToTheNearest(4))
		
		unknown06 = unpacked.unknown06
		unknown07 = unpacked.unknown07
		unknown08 = unpacked.unknown08
		unknown09 = Int32(fixedPoint: unpacked.unknown09)
		unknown10 = Int32(fixedPoint: unpacked.unknown10)
		bannerTextID = unpacked.bannerTextID
		
		loadingZoneCount = UInt32(unpacked.loadingZones.count)
		loadingZonesOffset = thingAOffset + thingACount * 8
		
		cameraPositionCount = UInt32(unpacked.cameraPositions.count)
		cameraPositionsOffset = loadingZonesOffset + loadingZoneCount * 0x14
		
		thingDCount = UInt32(unpacked.thingD.count)
		thingDOffsetsOffset = cameraPositionsOffset + cameraPositionCount * 0xC
		
		thingD = unpacked.thingD.map(ThingD.init)
		
		thingDOffsets = makeOffsets(
			start: thingDOffsetsOffset + thingDCount * 4,
			sizes: thingD.map { $0.size() }
		)
		
		fossilSpawnCount = UInt32(unpacked.fossilSpawns.count)
		fossilSpawnOffsetsOffset = thingDOffsetsOffset + thingDCount * 4 + thingD.map { $0.size() }.sum()
		
		fossilSpawns = unpacked.fossilSpawns.map(FossilSpawn.init)
		
		fossilSpawnOffsets = makeOffsets(
			start: fossilSpawnOffsetsOffset + fossilSpawnCount * 4,
			sizes: fossilSpawns.map { $0.size() }
		)
		
		breakableRockCount = UInt32(unpacked.breakableRocks.count)
		breakableRockOffsetsOffset = fossilSpawnOffsetsOffset + fossilSpawnCount * 4 + fossilSpawns.map { $0.size() }.sum()
		
		breakableRocks = unpacked.breakableRocks.map(BreakableRock.init)
		
		breakableRockOffsets = makeOffsets(
			start: breakableRockOffsetsOffset + breakableRockCount * 4,
			sizes: breakableRocks.map { $0.size() }
		)
		
		backgroundGradientTopOffset = breakableRockOffsetsOffset + breakableRockCount * 4 + breakableRocks.map { $0.size() }.sum()
		backgroundGradientBottomOffset = backgroundGradientTopOffset + 4
		
		unknown24 = unpacked.unknown24
		
		mapName = unpacked.mapName
		
		collisionMapName = unpacked.collisionMapName
		
		thingA = unpacked.thingA.map(ThingA.init)
		
		loadingZones = unpacked.loadingZones.map(LoadingZone.init)
		
		cameraPositions = unpacked.cameraPositions.map(CameraPosition.init)
		
		backgroundGradientTop = unpacked.backgroundGradientTop.bytes
		
		backgroundGradientBottom = unpacked.backgroundGradientBottom.bytes
	}
}

extension MAP.Packed.ThingA {
	init(_ unpacked: MAP.Unpacked.ThingA) {
		topScreenImage = unpacked.topScreenImage
		unknown2 = unpacked.unknown2
	}
}

extension MAP.Packed.LoadingZone {
	init(_ unpacked: MAP.Unpacked.LoadingZone) {
		id = unpacked.id
		x = unpacked.x
		y = unpacked.y
		rotation = Int32(fixedPoint: unpacked.rotation, fractionBits: 16)
	}
}

extension MAP.Packed.CameraPosition {
	static let null = Self(fov: 0, verticalAngle: 0, horizontalAngle: 0, distance: 0)
	
	init(_ unpacked: MAP.Unpacked.CameraPosition) {
		fov = Int16(fixedPoint: unpacked.fov, fractionBits: 4)
		verticalAngle = Int16(fixedPoint: unpacked.verticalAngle, fractionBits: 8)
		horizontalAngle = Int32(fixedPoint: unpacked.horizontalAngle)
		distance = Int32(fixedPoint: unpacked.distance)
	}
}

extension MAP.Packed.ThingD {
	init(_ unpacked: MAP.Unpacked.ThingD) {
		cameraPositionOffset = unpacked.cameraPositon == nil ? 0 : 0x14
		
		x = unpacked.unknown2
		y = unpacked.unknown3
		unknown4 = unpacked.unknown4
		unknown5 = unpacked.unknown5
		
		cameraPosition = unpacked.cameraPositon.map(MAP.Packed.CameraPosition.init) ?? .null
	}
	
	func size() -> UInt32 {
		0x14 + (cameraPositionOffset == 0 ? 0 : 0xC)
	}
}

extension MAP.Packed.FossilSpawn {
	init(_ unpacked: MAP.Unpacked.FossilSpawn) {
		unknown1 = unpacked.unknown1
		zone = unpacked.zone
		sonarUpgrades = unpacked.sonarUpgrades
		maxSpawns = unpacked.maxSpawns
		
		unknown2 = unpacked.unknown2
		unknown3 = unpacked.unknown3
		
		thingACount = UInt32(unpacked.thingAs.count)
		
		thingBCount = UInt32(unpacked.thingBs.count)
		thingBOffset = thingAOffset + thingACount * 4
		
		thingCCount = UInt32(unpacked.thingCs.count)
		thingCOffsetsOffset = thingBOffset + thingBCount * 0x30
		
		thingAs = unpacked.thingAs
		
		thingBs = unpacked.thingBs.map(ThingB.init)
		
		// TODO: is this size right? are they all 0x20???
		thingCOffsets = makeOffsets(
			start: thingCOffsetsOffset + thingCCount * 4,
			sizes: repeatElement(0x20, count: Int(thingCCount))
		)
		
		thingCs = unpacked.thingCs.map(ThingC.init)
	}
	
	func size() -> UInt32 {
		0x30 +
		(thingACount * 4) +
		(thingBCount * 0x30) +
		(thingCCount * 4) + // offsets
		(thingCCount * 0x20)
	}
}

extension MAP.Packed.FossilSpawn.ThingB {
	init(_ unpacked: MAP.Unpacked.FossilSpawn.ThingB) {
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
	}
}

extension MAP.Packed.FossilSpawn.ThingC {
	init(_ unpacked: MAP.Unpacked.FossilSpawn.ThingC) {
		vivosaurID = unpacked.vivosaurID
		unknown2 = unpacked.unknown2
		unknown3 = unpacked.unknown3
		unknown4 = unpacked.unknown4
		fossil1Chance = unpacked.fossil1Chance
		fossil2Chance = unpacked.fossil2Chance
		fossil3Chance = unpacked.fossil3Chance
		fossil4Chance = unpacked.fossil4Chance
	}
}

extension MAP.Packed.BreakableRock {
	init(_ unpacked: MAP.Unpacked.BreakableRock) {
		unknown1 = unpacked.unknown1
		spawnCount = unpacked.spawnCount
		entityID = unpacked.entityID
		rotation = Int32(fixedPoint: unpacked.rotation, fractionBits: 16)
		
		count = UInt32(unpacked.things.count)
		
		things = unpacked.things.map(Thing.init)
	}
	
	func size() -> UInt32 {
		0x18 + count * 8
	}
}

extension MAP.Packed.BreakableRock.Thing {
	init(_ unpacked: MAP.Unpacked.BreakableRock.Thing) {
		unknown1 = unpacked.unknown1
		unknown2 = unpacked.unknown2
	}
}

// MARK: unpacked
extension MAP.Unpacked: ProprietaryFileData {
	static let fileExtension = ".map.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> MAP.Packed {
		MAP.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: MAP.Packed, configuration: CarbonizerConfiguration) {
		unknown01 = packed.unknown01
		
		unknown02 = packed.unknown02
		unknown03 = packed.unknown03
		
		unknown06 = packed.unknown06
		unknown07 = packed.unknown07
		unknown08 = packed.unknown08
		unknown09 = Double(fixedPoint: packed.unknown09)
		
		unknown10 = Double(fixedPoint: packed.unknown10)
		bannerTextID = packed.bannerTextID
		
		unknown24 = packed.unknown24
		
		mapName = packed.mapName
		
		collisionMapName = packed.collisionMapName
		
		thingA = packed.thingA.map(ThingA.init)
		
		loadingZones = packed.loadingZones.map(LoadingZone.init)
		
		cameraPositions = packed.cameraPositions.map(CameraPosition.init)
		
		thingD = packed.thingD.map(ThingD.init)
		
		fossilSpawns = packed.fossilSpawns.map(FossilSpawn.init)
		
		breakableRocks = packed.breakableRocks.map(BreakableRock.init)
		
		backgroundGradientTop = Color(packed.backgroundGradientTop)
		
		backgroundGradientBottom = Color(packed.backgroundGradientBottom)
	}
}

extension MAP.Unpacked.ThingA {
	init(_ packed: MAP.Packed.ThingA) {
		topScreenImage = packed.topScreenImage
		unknown2 = packed.unknown2
	}
}

extension MAP.Unpacked.LoadingZone {
	init(_ packed: MAP.Packed.LoadingZone) {
		id = packed.id
		x = packed.x
		y = packed.y
		rotation = Double(fixedPoint: packed.rotation, fractionBits: 16)
	}
}

extension MAP.Unpacked.CameraPosition {
	init(_ packed: MAP.Packed.CameraPosition) {
		fov = Double(fixedPoint: packed.fov, fractionBits: 4)
		verticalAngle = Double(fixedPoint: packed.verticalAngle, fractionBits: 8)
		horizontalAngle = Double(fixedPoint: packed.horizontalAngle)
		distance = Double(fixedPoint: packed.distance)
	}
}

extension MAP.Unpacked.ThingD {
	init(_ packed: MAP.Packed.ThingD) {
		unknown2 = packed.x
		unknown3 = packed.y
		unknown4 = packed.unknown4
		unknown5 = packed.unknown5
		
		cameraPositon = packed.cameraPosition.map(MAP.Unpacked.CameraPosition.init)
	}
}

extension MAP.Unpacked.FossilSpawn {
	init(_ packed: MAP.Packed.FossilSpawn) {
		unknown1 = packed.unknown1
		zone = packed.zone
		sonarUpgrades = packed.sonarUpgrades
		maxSpawns = packed.maxSpawns
		
		unknown2 = packed.unknown2
		unknown3 = packed.unknown3
		
		thingAs = packed.thingAs
		
		thingBs = packed.thingBs.map(ThingB.init)
		
		thingCs = packed.thingCs.map(ThingC.init)
	}
}

extension MAP.Unpacked.FossilSpawn.ThingB {
	init(_ packed: MAP.Packed.FossilSpawn.ThingB) {
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
	}
}

extension MAP.Unpacked.FossilSpawn.ThingC {
	init(_ packed: MAP.Packed.FossilSpawn.ThingC) {
		vivosaurID = packed.vivosaurID
		_vivosaur = vivosaurNames[vivosaurID]
		
		unknown2 = packed.unknown2
		unknown3 = packed.unknown3
		unknown4 = packed.unknown4
		fossil1Chance = packed.fossil1Chance
		fossil2Chance = packed.fossil2Chance
		fossil3Chance = packed.fossil3Chance
		fossil4Chance = packed.fossil4Chance
	}
}

extension MAP.Unpacked.BreakableRock {
	init(_ packed: MAP.Packed.BreakableRock) {
		unknown1 = packed.unknown1
		spawnCount = packed.spawnCount
		
		entityID = packed.entityID
		_entity = entityNames[entityID]
		
		rotation = Double(fixedPoint: packed.rotation, fractionBits: 16)
		
		things = packed.things.map(Thing.init)
	}
}

extension MAP.Unpacked.BreakableRock.Thing {
	init(_ packed: MAP.Packed.BreakableRock.Thing) {
		unknown1 = packed.unknown1
		unknown2 = packed.unknown2
	}
}
