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
			var flippedHorizontally: UInt8
			var unbreakable: UInt8
			var destroyable: UInt8
			
			var completionForeground: UInt8
			
			var showScore: UInt8
			var unknown4: UInt8 = 0
			var unknown5: UInt8 = 0
			
			var fossilImage: UInt32
			var rockImage: UInt32
			
			var fossilHardness: UInt32 // fixed-point
			var rockHardness: UInt32 // fixed-point
			
			var buyPrice: UInt32
			var sellPrice: UInt32
			var sellPriceBeforeCleaning: UInt32
			
			var kl33nDialogue: UInt32
			var fossilName: UInt32 // jewels/droppings only
			var unknown8: UInt32 = 0
			
			var time: UInt32
			var passingScore: UInt32
			
			var completionBackground: UInt32
			
			var unknownsCount: UInt32 // always 2 for valid vivos
			var unknownsOffset: UInt32 = 0x44
			@Count(givenBy: \Self.unknownsCount)
			@Offset(givenBy: \Self.unknownsOffset)
			var shockwaveResistances: [UInt32] // hammer then drill
			// hammer:
			// - 0.4, 0.5, 0.6
			// drill:
			// - 0.5, 0.7
			// - only 0.7 for goyle
		}
	}
	
	struct Unpacked {
		var kasekis: [Kaseki?]
		
		struct Kaseki: Equatable {
			var _label: String?
			
			var isEntry: Bool
			var flippedHorizontally: Bool
			var unbreakable: Bool
			var destroyable: Bool
			
			var completionForeground: CompletionBones
			var completionBackground: CompletionBones
			
			var showScore: Bool
			
			var fossilImage: UInt32
			var rockImage: UInt32
			
			var fossilHardness: Double
			var rockHardness: Double
			
			var buyPrice: UInt32
			var sellPrice: UInt32
			
			var sellPriceBeforeCleaning: UInt32
			var kl33nDialogue: FossilType
			var fossilName: UInt32
			
			var time: UInt32
			var passingScore: UInt32
			
			var shockwaveResistances: [Double]
			
			enum CompletionBones: String, Codable {
				case fourBones, egg, headOnly, mystery
			}
			
			enum FossilType: String, Codable {
				case normal, jewel, dropping
			}
		}
	}
}

// MARK: packed
extension RLS.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) throws -> RLS.Unpacked {
		try RLS.Unpacked(self, configuration: configuration)
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
			self = RLS.Packed.Kaseki(isEntry: 0, flippedHorizontally: 0, unbreakable: 0, destroyable: 0, completionForeground: 0, showScore: 0, unknown4: 0, unknown5: 0, fossilImage: 0, rockImage: 0, fossilHardness: 0, rockHardness: 0, buyPrice: 0, sellPrice: 0, sellPriceBeforeCleaning: 0, kl33nDialogue: 0, fossilName: 0, unknown8: 0, time: 0, passingScore: 0, completionBackground: 0, unknownsCount: 0, unknownsOffset: 0x44, shockwaveResistances: [])
			return
		}
		
		isEntry = kaseki.isEntry ? 1 : 0
		flippedHorizontally = kaseki.flippedHorizontally ? 1 : 0
		unbreakable = kaseki.unbreakable ? 1 : 0
		destroyable = kaseki.destroyable ? 1 : 0
		
		completionForeground = UInt8(kaseki.completionForeground.raw)
		completionBackground = UInt32(kaseki.completionBackground.raw)
		
		showScore = kaseki.showScore ? 1 : 0
		
		fossilImage = kaseki.fossilImage
		rockImage = kaseki.rockImage
		
		fossilHardness = UInt32(kaseki.fossilHardness * 4096)
		rockHardness = UInt32(kaseki.rockHardness * 4096)
		
		buyPrice = kaseki.buyPrice
		sellPrice = kaseki.sellPrice
		
		sellPriceBeforeCleaning = kaseki.sellPriceBeforeCleaning
		kl33nDialogue = kaseki.kl33nDialogue.raw
		fossilName = kaseki.fossilName
		
		time = kaseki.time
		passingScore = kaseki.passingScore
		
		unknownsCount = UInt32(kaseki.shockwaveResistances.count)
		shockwaveResistances = kaseki.shockwaveResistances.map { UInt32($0 * 4096) }
	}
}

extension RLS.Unpacked.Kaseki.CompletionBones {
	var raw: Int {
		switch self {
			case .fourBones: 0
			case .egg: 1
			case .headOnly: 2
			case .mystery: 3
		}
	}
}

extension RLS.Unpacked.Kaseki.FossilType {
	var raw: UInt32 {
		switch self {
			case .normal: 0
			case .jewel: 1
			case .dropping: 2
		}
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
	
	fileprivate init(_ packed: RLS.Packed, configuration: CarbonizerConfiguration) throws {
		kasekis = try packed.kasekis.enumerated().map(Kaseki.init)
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
	init?(index: Int, _ kaseki: RLS.Packed.Kaseki) throws {
		_label = fossilNames[Int32(index)]
		
		isEntry = kaseki.isEntry > 0
		guard isEntry else { return nil }
		flippedHorizontally = kaseki.flippedHorizontally > 0
		unbreakable = kaseki.unbreakable > 0
		destroyable = kaseki.destroyable > 0
		
		completionForeground = try CompletionBones(kaseki.completionForeground)
		showScore = kaseki.showScore > 0
		
		fossilImage = kaseki.fossilImage
		rockImage = kaseki.rockImage
		
		fossilHardness = Double(kaseki.fossilHardness) / 4096
		rockHardness = Double(kaseki.rockHardness) / 4096
		
		buyPrice = kaseki.buyPrice
		sellPrice = kaseki.sellPrice
		
		sellPriceBeforeCleaning = kaseki.sellPriceBeforeCleaning
		kl33nDialogue = try FossilType(kaseki.kl33nDialogue)
		fossilName = kaseki.fossilName
		
		time = kaseki.time
		passingScore = kaseki.passingScore
		
		completionBackground = try CompletionBones(kaseki.completionBackground)
		
		shockwaveResistances = kaseki.shockwaveResistances.map { Double($0) / 4096 }
	}
}

extension RLS.Unpacked.Kaseki.CompletionBones {
	struct InvalidID: Error, CustomStringConvertible {
		var id: Int
		
		var description: String {
			"invalid id for fossil completion fg/bg: \(id)"
		}
	}
	
	init(_ number: some FixedWidthInteger) throws(InvalidID) {
		self = switch number {
			case 0: .fourBones
			case 1: .egg
			case 2: .headOnly
			case 3: .mystery
			default: throw InvalidID(id: Int(number))
		}
	}
}

extension RLS.Unpacked.Kaseki.FossilType {
	struct InvalidID: Error, CustomStringConvertible {
		var id: UInt32
		
		var description: String {
			"invalid id for kl-33n dialogue: \(id)"
		}
	}
	
	init(_ raw: UInt32) throws(InvalidID) {
		self = switch raw {
			case 0: .normal
			case 1: .jewel
			case 2: .dropping
			default: throw InvalidID(id: raw)
		}
	}
}

// MARK: unpacked codable
extension RLS.Unpacked.Kaseki: Codable {
	enum CodingKeys: String, CodingKey {
		case _label =                  "_label"
		
		case isEntry =                 "is entry"
		case flippedHorizontally =     "flipped horizontally"
		case unbreakable =             "unbreakable"
		case destroyable =             "destroyable"
		
		case completionForeground =    "completion foreground"
		case completionBackground =    "completion background"
		
		case showScore =               "show score"
		
		case fossilImage =             "fossil image"
		case rockImage =               "rock image"
		
		case fossilHardness =          "fossil hardness"
		case rockHardness =            "rock hardness"
		
		case buyPrice =                "buy price"
		case sellPrice =               "sell price"
		case sellPriceBeforeCleaning = "sell price before cleaning"
		
		case kl33nDialogue =           "kl-33n dialogue"
		case fossilName =              "fossil name"
		
		case time =                    "time"
		case passingScore =            "passing score"
		
		case shockwaveResistances =    "shockwave resistances"
	}
}
