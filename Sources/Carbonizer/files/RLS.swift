import BinaryParser

enum RLS {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "RLS"
		var kasekiCount: UInt32
		var offsetsStart: UInt32 = 0xC
		@Count(givenBy: \Self.kasekiCount)
		@Offset(givenBy: \Self.offsetsStart)
		var offsets: [UInt32]
		@Offsets(givenBy: \Self.offsets)
		var kasekis: [Kaseki]
		
		@BinaryConvertible
		struct Kaseki {
			var isEntry: UInt8
			var unknown1: UInt8
			var unbreakable: UInt8
			var destroyable: UInt8
			
			var unknown2: UInt8 // only high for special vivos
								// setting to >0 makes it uncleanable
			var unknown3: UInt8 // only 0 for droppings and some specials
			var unknown4: UInt8 = 0
			var unknown5: UInt8 = 0
			
			var fossilImage: UInt32
			var rockImage: UInt32
			
			var fossilHardness: UInt32 // fixed-point
			var rockHardness: UInt32 // fixed-point
			
			var buyPrice: UInt32
			var sellPrice: UInt32
			
			var unknown6: UInt32 // 100 for jewels, 0 else
								 // selling price before cleaning?
								 // - nope—changing it doesnt work
			var unknown7: UInt32 // 1 for jewels, 2 for droppings, 0 else
			var fossilName: UInt32 // jewels/droppings only
			var unknown8: UInt32 = 0
			
			var time: UInt32
			var passingScore: UInt32
			
			var unknown9: UInt32 // same as unknown2
			
			var unknownsCount: UInt32 // always 2 for valid vivos
			var unknownsOffset: UInt32 = 0x44
			@Count(givenBy: \Self.unknownsCount)
			@Offset(givenBy: \Self.unknownsOffset)
			var unknowns: [UInt32] // 1st is resistance to being hit NEXT TO like damage resistance?
								   // shockwave damage
								   // 2nd is for drill resistance? somehow??
			
			// unknowns[0]:
			// - 0.4, 0.5, 0.6
			// unknowns[1]:
			// - 0.5, 0.7
			// - only 0.7 for goyle
		}
	}
	
	struct Unpacked {
		var kasekis: [Kaseki?]
		
		struct Kaseki: Equatable {
			var _label: String?
			
			var isEntry: Bool
			var unknown1: Bool
			var unbreakable: Bool
			var destroyable: Bool
			
			var unknown2: UInt8
			var unknown3: Bool
			
			var fossilImage: UInt32
			var rockImage: UInt32
			
			var fossilHardness: Double
			var rockHardness: Double
			
			var buyPrice: UInt32
			var sellPrice: UInt32
			
			var unknown6: UInt32
			var unknown7: UInt32
			var fossilName: UInt32
			
			var time: UInt32
			var passingScore: UInt32
			
			var unknown9: UInt32
			
			var unknownsCount: UInt32
			var unknownsOffset: UInt32
			var unknowns: [Double]
		}
	}
}

// MARK: packed
extension RLS.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> RLS.Unpacked {
		RLS.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: RLS.Unpacked, configuration: CarbonizerConfiguration) {
		kasekiCount = UInt32(unpacked.kasekis.count)
		
		offsets = makeOffsets(
			start: offsetsStart + kasekiCount * 4,
			sizes: unpacked.kasekis.map(\.size)
		)
		
		kasekis = unpacked.kasekis.map(Kaseki.init)
	}
}

extension RLS.Unpacked.Kaseki? {
	var size: UInt32 {
		if self == nil {
			68
		} else {
			76
		}
	}
}

extension RLS.Packed.Kaseki {
	init(_ kaseki: RLS.Unpacked.Kaseki?) {
		guard let kaseki else {
			self = RLS.Packed.Kaseki(isEntry: 0, unknown1: 0, unbreakable: 0, destroyable: 0, unknown2: 0, unknown3: 0, unknown4: 0, unknown5: 0, fossilImage: 0, rockImage: 0, fossilHardness: 0, rockHardness: 0, buyPrice: 0, sellPrice: 0, unknown6: 0, unknown7: 0, fossilName: 0, unknown8: 0, time: 0, passingScore: 0, unknown9: 0, unknownsCount: 0, unknownsOffset: 0x44, unknowns: [])
			return
		}
		
		isEntry = kaseki.isEntry ? 1 : 0
		unknown1 = kaseki.unknown1 ? 1 : 0
		unbreakable = kaseki.unbreakable ? 1 : 0
		destroyable = kaseki.destroyable ? 1 : 0
		
		unknown2 = kaseki.unknown2
		unknown3 = kaseki.unknown3 ? 1 : 0
		
		fossilImage = kaseki.fossilImage
		rockImage = kaseki.rockImage
		
		fossilHardness = UInt32(kaseki.fossilHardness * 4096)
		rockHardness = UInt32(kaseki.rockHardness * 4096)
		
		buyPrice = kaseki.buyPrice
		sellPrice = kaseki.sellPrice
		
		unknown6 = kaseki.unknown6
		unknown7 = kaseki.unknown7
		fossilName = kaseki.fossilName
		
		time = kaseki.time
		passingScore = kaseki.passingScore
		
		unknown9 = kaseki.unknown9
		
		unknownsCount = kaseki.unknownsCount
		unknownsOffset = kaseki.unknownsOffset
		unknowns = kaseki.unknowns.map { UInt32($0 * 4096) }
	}
}

// MARK: unpacked
extension RLS.Unpacked: ProprietaryFileData {
	static let fileExtension = ".rls.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> RLS.Packed {
		RLS.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: RLS.Packed, configuration: CarbonizerConfiguration) {
		kasekis = packed.kasekis.enumerated().map(Kaseki.init)
	}
}

extension RLS.Unpacked: Codable {
	init(from decoder: Decoder) throws {
		kasekis = try [Kaseki?](from: decoder)
	}
	
	func encode(to encoder: Encoder) throws {
		try kasekis.encode(to: encoder)
	}
}

extension RLS.Unpacked.Kaseki {
	init?(index: Int, _ kaseki: RLS.Packed.Kaseki) {
		_label = fossilNames[Int32(index)]
		
		isEntry = kaseki.isEntry > 0
		guard isEntry else { return nil }
		unknown1 = kaseki.unknown1 > 0
		unbreakable = kaseki.unbreakable > 0
		destroyable = kaseki.destroyable > 0
		
		unknown2 = kaseki.unknown2
		unknown3 = kaseki.unknown3 > 0
		
		fossilImage = kaseki.fossilImage
		rockImage = kaseki.rockImage
		
		fossilHardness = Double(kaseki.fossilHardness) / 4096
		rockHardness = Double(kaseki.rockHardness) / 4096
		
		buyPrice = kaseki.buyPrice
		sellPrice = kaseki.sellPrice
		
		unknown6 = kaseki.unknown6
		unknown7 = kaseki.unknown7
		fossilName = kaseki.fossilName
		
		time = kaseki.time
		passingScore = kaseki.passingScore
		
		unknown9 = kaseki.unknown9
		
		unknownsCount = kaseki.unknownsCount
		unknownsOffset = kaseki.unknownsOffset
		unknowns = kaseki.unknowns.map { Double($0) / 4096 }
	}
}

// MARK: unpacked codable
extension RLS.Unpacked.Kaseki: Codable {
	enum CodingKeys: String, CodingKey {
		case _label =         "_label"
		
		case isEntry =        "is entry"
		case unknown1 =       "unknown 1"
		case unbreakable =    "unbreakable"
		case destroyable =    "destroyable"
		
		case unknown2 =       "unknown 2"
		case unknown3 =       "unknown 3"
		
		case fossilImage =    "fossil image"
		case rockImage =      "rock image"
		
		case fossilHardness = "fossil hardness"
		case rockHardness =   "rock hardness"
		
		case buyPrice =       "buy price"
		case sellPrice =      "sell price"
		
		case unknown6 =       "unknown 6"
		case unknown7 =       "unknown 7"
		case fossilName =     "fossil name"
		
		case time =           "time"
		case passingScore =   "passing score"
		
		case unknown9 =       "unknown 9"
		
		case unknownsCount =  "unknowns count"
		case unknownsOffset = "unknowns offset"
		case unknowns =       "unknowns"
	}
}
