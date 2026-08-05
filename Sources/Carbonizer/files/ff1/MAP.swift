import BinaryParser

// c - camera
// e - excavate (fossils)
// g - objects
// m - maps
// r - regions

enum MAP {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "MAP"
		
		var mapNameOffset: UInt32 = 0x6C
		var mapNameForCollisionOffset: UInt32
		
		var unknown01: Int32 // 0-18 (skipping a bunch)
		
		// 0x10
		var unknown02: Int32 // 0-26 (skipping 1)
		var unknown03: Int32 // 1-34 (skipping a bunch)
		
		var topScreenImageCount: UInt32
		var topScreenImagesOffset: UInt32
		
		// 0x20
		var mapDotDoesNotMove: Int32
		var mapDotX: Int32
		var mapDotY: Int32
		var mapDotScale: FixedPoint2012
		
		// 0x30
		var movementSpeed: FixedPoint2012
		var bannerTextID: UInt32
		
		var regionCount: UInt32
		var regionsOffset: UInt32
		
		// 0x40
		var cameraPositionCount: UInt32
		var cameraPositionsOffset: UInt32
		
		var thingDCount: UInt32
		var thingDOffsetsOffset: UInt32
		
		// 0x50
		var fossilSpawnCount: UInt32
		var fossilSpawnOffsetsOffset: UInt32
		
		var objectCount: UInt32
		var objectOffsetsOffset: UInt32
		
		// 0x60
		var backgroundGradientTopOffset: UInt32
		var backgroundGradientBottomOffset: UInt32
		
		var unknown24: UInt32 // unknown
		
		@Offset(givenBy: \Self.mapNameOffset)
		var mapName: String
		
		@Offset(givenBy: \Self.mapNameForCollisionOffset)
		var mapNameForCollision: String
		
		@Count(givenBy: \Self.topScreenImageCount)
		@Offset(givenBy: \Self.topScreenImagesOffset)
		var topScreenImages: [TopScreenImage]
		
		@Count(givenBy: \Self.regionCount)
		@Offset(givenBy: \Self.regionsOffset)
		var regions: [Region]
		
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
		
		@Count(givenBy: \Self.objectCount)
		@Offset(givenBy: \Self.objectOffsetsOffset)
		var objectOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.objectOffsets)
		var objects: [Object]
		
		@Count(3)
		@Offset(givenBy: \Self.backgroundGradientTopOffset)
		var backgroundGradientTop: [UInt8]
		
		@Count(3)
		@Offset(givenBy: \Self.backgroundGradientBottomOffset)
		var backgroundGradientBottom: [UInt8]
		
		@FourByteAlign
		var fourByteAlign: ()
		
		@BinaryConvertible
		struct TopScreenImage {
			// always 1–5, `images/town_map_*`
			// 1-fighter, 2-park, 3-guild, 4—park with bea ginner, 5—park with fossil cannon
			var townMapNumber: UInt32
			var enabledFlag: UInt32
		}
		
		@BinaryConvertible
		struct Region { // map/r
			var id: Int32
			
			// what do x and y do??? what abt the grd file?
			// they seem to match up with their location, but changing them does... nothing???
			var x: Int32
			var y: Int32
			
			var rotation: FixedPoint1616
			// angle but not degrees again
			// - rotating a door makes the player walk out sideways
			
			var unknown5: Int32 = 0
		}
		
		@BinaryConvertible
		struct CameraPosition: Equatable {
			// first one effects the camera when walking around, no clue abt the rest (not sub areas, not map/c)
			var fov: FixedPoint124
			var verticalAngle: FixedPoint88
			var horizontalAngle: FixedPoint2012
			var distance: FixedPoint2012
			
			init(
				fov: FixedPoint124,
				verticalAngle: FixedPoint88,
				horizontalAngle: FixedPoint2012,
				distance: FixedPoint2012
			) {
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
			var isEnabledFlag: Int32 // (type 5 ?)
			var spawnCount: Int32
			
			var unknown2: Int32
			var unknown3: Int32
			var thingACount: UInt32
			var thingAOffset: UInt32 = 0x30
			
			var thingBCount: UInt32
			var thingBOffsetsOffset: UInt32
			var vivosaurCount: UInt32
			var vivosaurOffsetsOffset: UInt32
			
			@Count(givenBy: \Self.thingACount)
			@Offset(givenBy: \Self.thingAOffset)
			var thingAs: [Int32]
			
			@Count(givenBy: \Self.thingBCount)
			@Offset(givenBy: \Self.thingBOffsetsOffset)
			var thingBOffsets: [UInt32]
			
			@Offsets(givenBy: \Self.thingBOffsets)
			var thingBs: [ThingB]
			
			@Count(givenBy: \Self.vivosaurCount)
			@Offset(givenBy: \Self.vivosaurOffsetsOffset)
			var vivosaurOffsets: [UInt32]
			
			@Offsets(givenBy: \Self.vivosaurOffsets)
			var vivosaurs: [Vivosaur]
			
			@BinaryConvertible
			struct ThingB {
				var unknownFlag: Int32
				
				var count: UInt32
				var offset: UInt32 = 0xc
				
				@Count(givenBy: \Self.count)
				@Offset(givenBy: \Self.offset)
				var values: [Int32]
			}
			
			@BinaryConvertible
			struct Vivosaur {
				var vivosaurID: Int32
				
				var chance: Int32
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
		struct Object { // map/g
			var isEnabledFlag: Int32 // often 0, otherwise seems like an index?
			                    // not dialogue, not event
			                    // like in the ~5000s range
			                    // a flag ?
			var spawnCount: Int32
			var entityID: Int32
			var rotation: FixedPoint1616
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
				var unknown1: FixedPoint2012
				var unknown2: FixedPoint2012
			}
		}
	}
	
	struct Unpacked: Codable {
		var unknown01: Int32
		
		var unknown02: Int32
		var unknown03: Int32
		
		var mapDotMoves: Bool
		var mapDotX: Int32
		var mapDotY: Int32
		var mapDotScale: Double
		
		var movementSpeed: Double
		
		var bannerTextID: UInt32
		var _bannerText: String?
		
		var unknown24: UInt32 // unknown
		
		var mapName: String
		var mapNameForCollision: String
		
		var topScreenImages: [TopScreenImage]
		
		var regions: [Region]
		
		var cameraPositions: [CameraPosition]
		
		var thingD: [ThingD]
		
		var fossilSpawns: [FossilSpawn]
		
		var objects: [Object]
		
		var backgroundGradientTop: Color
		
		var backgroundGradientBottom: Color
		
		struct TopScreenImage: Codable {
			var townMapNumber: UInt32
			var enabledFlag: UInt32
		}
		
		struct Region: Codable {
			var _grd_label: String
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
			var x: Int32
			var y: Int32
			var unknown4: Int32
			var unknown5: Int32
			
			var cameraPositon: MAP.Unpacked.CameraPosition?
		}
		
		struct FossilSpawn: Codable {
			var unknown1: Int32
			var zone: Int32
			var isEnabledFlag: Int32
			var spawnCount: Int32
			
			var unknown2: Int32
			var unknown3: Int32
			
			var thingAs: [Int32]
			
			var thingBs: [ThingB]
			
			var vivosaurs: [Vivosaur]
			
			struct ThingB: Codable {
				var unknownFlag: Int32
				
				var values: [Int32]
			}
			
			struct Vivosaur: Codable {
				var vivosaurID: Int32
				var _vivosaur: String?
				
				var chance: Int32
				var unknown3: Int32
				var unknown4: Int32
				
				var fossil1Chance: Int32
				var fossil2Chance: Int32
				var fossil3Chance: Int32
				var fossil4Chance: Int32
			}
		}
		
		struct Object: Codable {
			var isEnabledFlag: Int32
			var spawnCount: Int32
			
			var entityID: Int32
			var _entity: String?
			
			var rotation: Double
			
			var things: [Thing]
			
			struct Thing: Codable {
				var unknown1: Double
				var unknown2: Double
			}
		}
	}
}

// MARK: packed
extension MAP.Packed: ProprietaryFileData {
	static let fileExtension = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> MAP.Unpacked {
		MAP.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: MAP.Unpacked, configuration: Configuration) {
		mapNameForCollisionOffset = mapNameOffset + UInt32(unpacked.mapName.utf8CString.count.roundedUpToTheNearest(4))
		
		unknown01 = unpacked.unknown01
		
		unknown02 = unpacked.unknown02
		unknown03 = unpacked.unknown03
		
		topScreenImageCount = UInt32(unpacked.topScreenImages.count)
		topScreenImagesOffset = mapNameForCollisionOffset + UInt32(unpacked.mapNameForCollision.utf8CString.count.roundedUpToTheNearest(4))
		
		mapDotDoesNotMove = unpacked.mapDotMoves ? 0 : 1
		mapDotX = unpacked.mapDotX
		mapDotY = unpacked.mapDotY
		mapDotScale = FixedPoint2012(unpacked.mapDotScale)
		
		movementSpeed = FixedPoint2012(unpacked.movementSpeed)
		bannerTextID = unpacked.bannerTextID
		
		regionCount = UInt32(unpacked.regions.count)
		regionsOffset = topScreenImagesOffset + topScreenImageCount * 8
		
		cameraPositionCount = UInt32(unpacked.cameraPositions.count)
		cameraPositionsOffset = regionsOffset + regionCount * 0x14
		
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
		
		objectCount = UInt32(unpacked.objects.count)
		objectOffsetsOffset = fossilSpawnOffsetsOffset + fossilSpawnCount * 4 + fossilSpawns.map { $0.size() }.sum()
		
		objects = unpacked.objects.map(Object.init)
		
		objectOffsets = makeOffsets(
			start: objectOffsetsOffset + objectCount * 4,
			sizes: objects.map { $0.size() }
		)
		
		backgroundGradientTopOffset = objectOffsetsOffset + objectCount * 4 + objects.map { $0.size() }.sum()
		backgroundGradientBottomOffset = backgroundGradientTopOffset + 4
		
		unknown24 = unpacked.unknown24
		
		mapName = unpacked.mapName
		mapNameForCollision = unpacked.mapNameForCollision
		
		topScreenImages = unpacked.topScreenImages.map(TopScreenImage.init)
		
		regions = unpacked.regions.map(Region.init)
		
		cameraPositions = unpacked.cameraPositions.map(CameraPosition.init)
		
		backgroundGradientTop = unpacked.backgroundGradientTop.bytes
		
		backgroundGradientBottom = unpacked.backgroundGradientBottom.bytes
	}
}

extension MAP.Packed.TopScreenImage {
	init(_ unpacked: MAP.Unpacked.TopScreenImage) {
		townMapNumber = unpacked.townMapNumber
		enabledFlag = unpacked.enabledFlag
	}
}

extension MAP.Packed.Region {
	init(_ unpacked: MAP.Unpacked.Region) {
		id = unpacked.id
		x = unpacked.x
		y = unpacked.y
		rotation = FixedPoint1616(unpacked.rotation)
	}
}

extension MAP.Packed.CameraPosition {
	static let null = Self(fov: 0, verticalAngle: 0, horizontalAngle: 0, distance: 0)
	
	init(_ unpacked: MAP.Unpacked.CameraPosition) {
		fov = FixedPoint124(unpacked.fov)
		verticalAngle = FixedPoint88(unpacked.verticalAngle)
		horizontalAngle = FixedPoint2012(unpacked.horizontalAngle)
		distance = FixedPoint2012(unpacked.distance)
	}
}

extension MAP.Packed.ThingD {
	init(_ unpacked: MAP.Unpacked.ThingD) {
		cameraPositionOffset = unpacked.cameraPositon == nil ? 0 : 0x14
		
		x = unpacked.x
		y = unpacked.y
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
		isEnabledFlag = unpacked.isEnabledFlag
		spawnCount = unpacked.spawnCount
		
		unknown2 = unpacked.unknown2
		unknown3 = unpacked.unknown3
		
		thingACount = UInt32(unpacked.thingAs.count)
		
		thingBCount = UInt32(unpacked.thingBs.count)
		thingBOffsetsOffset = thingAOffset + thingACount * 4
		
		thingBs = unpacked.thingBs.map(ThingB.init)
		
		thingBOffsets = makeOffsets(
			start: thingBOffsetsOffset + thingBCount * 4,
			sizes: thingBs.map { $0.size() }
		)
		
		vivosaurCount = UInt32(unpacked.vivosaurs.count)
		// ThingBs are always 0x2c, plus 0x4 for the index
		// - this is a bit hacky but i cant think of a cleaner solution and this works *okay*
		vivosaurOffsetsOffset = thingBOffsetsOffset + thingBCount * 0x30
		
		thingAs = unpacked.thingAs
		
		// TODO: is this size right? are they all 0x20???
		vivosaurOffsets = makeOffsets(
			start: vivosaurOffsetsOffset + vivosaurCount * 4,
			sizes: repeatElement(0x20, count: Int(vivosaurCount))
		)
		
		vivosaurs = unpacked.vivosaurs.map(Vivosaur.init)
	}
	
	func size() -> UInt32 {
		0x30 +
		(thingACount * 4) +
		(thingBCount * 0x30) +
		(vivosaurCount * 4) + // offsets
		(vivosaurCount * 0x20)
	}
}

extension MAP.Packed.FossilSpawn.ThingB {
	init(_ unpacked: MAP.Unpacked.FossilSpawn.ThingB) {
		unknownFlag = unpacked.unknownFlag
		
		count = UInt32(unpacked.values.count)
		
		values = unpacked.values
	}
	
	func size() -> UInt32 {
		16 + UInt32(values.count * 4)
	}
}

extension MAP.Packed.FossilSpawn.Vivosaur {
	init(_ unpacked: MAP.Unpacked.FossilSpawn.Vivosaur) {
		vivosaurID = unpacked.vivosaurID
		
		chance = unpacked.chance
		unknown3 = unpacked.unknown3
		unknown4 = unpacked.unknown4
		
		fossil1Chance = unpacked.fossil1Chance
		fossil2Chance = unpacked.fossil2Chance
		fossil3Chance = unpacked.fossil3Chance
		fossil4Chance = unpacked.fossil4Chance
	}
}

extension MAP.Packed.Object {
	init(_ unpacked: MAP.Unpacked.Object) {
		isEnabledFlag = unpacked.isEnabledFlag
		spawnCount = unpacked.spawnCount
		entityID = unpacked.entityID
		rotation = FixedPoint1616(unpacked.rotation
		)
		
		count = UInt32(unpacked.things.count)
		
		things = unpacked.things.map(Thing.init)
	}
	
	func size() -> UInt32 {
		0x18 + count * 8
	}
}

extension MAP.Packed.Object.Thing {
	init(_ unpacked: MAP.Unpacked.Object.Thing) {
		unknown1 = FixedPoint2012(unpacked.unknown1)
		unknown2 = FixedPoint2012(unpacked.unknown2)
	}
}

// MARK: unpacked
extension MAP.Unpacked: ProprietaryFileData {
	static let fileExtension = ".map.json"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> MAP.Packed {
		MAP.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: MAP.Packed, configuration: Configuration) {
		unknown01 = packed.unknown01
		
		unknown02 = packed.unknown02
		unknown03 = packed.unknown03
		
		mapDotMoves = packed.mapDotDoesNotMove == 0
		mapDotX = packed.mapDotX
		mapDotY = packed.mapDotY
		mapDotScale = Double(packed.mapDotScale)
		
		movementSpeed = Double(packed.movementSpeed)
		bannerTextID = packed.bannerTextID
		
		unknown24 = packed.unknown24
		
		mapName = packed.mapName
		mapNameForCollision = packed.mapNameForCollision
		
		topScreenImages = packed.topScreenImages.map(TopScreenImage.init)
		
		regions = packed.regions.enumerated().map(Region.init)
		
		cameraPositions = packed.cameraPositions.map(CameraPosition.init)
		
		thingD = packed.thingD.map(ThingD.init)
		
		fossilSpawns = packed.fossilSpawns.map(FossilSpawn.init)
		
		objects = packed.objects.map(Object.init)
		
		backgroundGradientTop = Color(packed.backgroundGradientTop)
		
		backgroundGradientBottom = Color(packed.backgroundGradientBottom)
	}
}

extension MAP.Unpacked.TopScreenImage {
	init(_ packed: MAP.Packed.TopScreenImage) {
		townMapNumber = packed.townMapNumber
		enabledFlag = packed.enabledFlag
	}
}

extension MAP.Unpacked.Region {
	init(index: Int, _ packed: MAP.Packed.Region) {
		_grd_label = String(GRD.Unpacked.letterLookup[index]) 
		
		id = packed.id
		x = packed.x
		y = packed.y
		rotation = Double(packed.rotation)
	}
}

extension MAP.Unpacked.CameraPosition {
	init(_ packed: MAP.Packed.CameraPosition) {
		fov = Double(packed.fov)
		verticalAngle = Double(packed.verticalAngle)
		horizontalAngle = Double(packed.horizontalAngle)
		distance = Double(packed.distance)
	}
}

extension MAP.Unpacked.ThingD {
	init(_ packed: MAP.Packed.ThingD) {
		x = packed.x
		y = packed.y
		unknown4 = packed.unknown4
		unknown5 = packed.unknown5
		
		cameraPositon = packed.cameraPosition.map(MAP.Unpacked.CameraPosition.init)
	}
}

extension MAP.Unpacked.FossilSpawn {
	init(_ packed: MAP.Packed.FossilSpawn) {
		unknown1 = packed.unknown1
		zone = packed.zone
		isEnabledFlag = packed.isEnabledFlag
		spawnCount = packed.spawnCount
		
		unknown2 = packed.unknown2
		unknown3 = packed.unknown3
		
		thingAs = packed.thingAs
		
		thingBs = packed.thingBs.map(ThingB.init)
		
		vivosaurs = packed.vivosaurs.map(Vivosaur.init)
	}
}

extension MAP.Unpacked.FossilSpawn.ThingB {
	init(_ packed: MAP.Packed.FossilSpawn.ThingB) {
		unknownFlag = packed.unknownFlag
		
		values = packed.values
	}
}

extension MAP.Unpacked.FossilSpawn.Vivosaur {
	init(_ packed: MAP.Packed.FossilSpawn.Vivosaur) {
		vivosaurID = packed.vivosaurID
		_vivosaur = vivosaurNames[vivosaurID]
		
		chance = packed.chance
		unknown3 = packed.unknown3
		unknown4 = packed.unknown4
		
		fossil1Chance = packed.fossil1Chance
		fossil2Chance = packed.fossil2Chance
		fossil3Chance = packed.fossil3Chance
		fossil4Chance = packed.fossil4Chance
	}
}

extension MAP.Unpacked.Object {
	init(_ packed: MAP.Packed.Object) {
		isEnabledFlag = packed.isEnabledFlag
		spawnCount = packed.spawnCount
		
		entityID = packed.entityID
		_entity = entityNames[entityID]
		
		rotation = Double(packed.rotation)
		
		things = packed.things.map(Thing.init)
	}
}

extension MAP.Unpacked.Object.Thing {
	init(_ packed: MAP.Packed.Object.Thing) {
		unknown1 = Double(packed.unknown1)
		unknown2 = Double(packed.unknown2)
	}
}
