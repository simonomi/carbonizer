import BinaryParser

// btl_adjust_defs
enum DBA {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "DBA"
		
		var defaultHitRate: FixedPoint2012 // 0.8
		var hitRateDivisor: FixedPoint2012 // 10
		var minimumHitRate: FixedPoint2012 // 0.1
		
		// 0x10
		var unknown004: FixedPoint2012 // 1
		var unknown005: FixedPoint2012 // 1
		
		var critDamageLowerBound: FixedPoint2012 // 1.45
		var critDamageUpperBound: FixedPoint2012 // 1.55
		
		// 0x20
		var damageVarianceLowerBound: FixedPoint2012 // 0.95
		var damageVarianceUpperBound: FixedPoint2012 // 1.05
		
		var unknown010: FixedPoint2012 // 0.45
		var unknown011: FixedPoint2012 // 0.55
		
		// 0x30
		var typeAdvantageMultiplier: FixedPoint2012 // 1.5
		var typeDisadvantageMultiplier: FixedPoint2012 // 0.75
		var typeNeutralMultiplier: FixedPoint2012 // 1
		
		var partingBlowAttackMultiplier: FixedPoint2012 // 1
		// 0x40
		var partingBlowDefenseMultiplier: FixedPoint2012 // 0.5
		var partingBlowAccuracyMultiplier: FixedPoint2012 // 1
		var partingBlowSpeedMultiplier: FixedPoint2012 // 0.5
		
		var unknown019: FixedPoint2012 // 1
		
		// 0x50
		var autoCounterFactor: FixedPoint2012 // 0.1
		
		var unknown021: Int32 // 1
		var unknown022: Int32 // 60
		var unknown023: Int32 // -20
		// 0x60
		var unknown024: Int32 // 0
		var unknown025: Int32 // 20
		var unknown026: Int32 // 12
		var unknown027: Int32 // -60
		// 0x70
		var unknown028: Int32 // -23
		var unknown029: Int32 // -10
		var unknown030: Int32 // 60
		var unknown031: Int32 // -20
		// 0x80
		var unknown032: Int32 // 20
		var unknown033: Int32 // 24
		var unknown034: Int32 // 24
		var unknown035: Int32 // -60
		// 0x90
		var unknown036: Int32 // -6
		var unknown037: Int32 // -10
		var unknown038: Int32 // 50
		var unknown039: Int32 // -20
		// 0xa0
		var unknown040: Int32 // 12
		var unknown041: Int32 // 30
		var unknown042: Int32 // 12
		var unknown043: Int32 // -60
		// 0xb0
		var unknown044: Int32 // -23
		var unknown045: Int32 // -20
		var unknown046: Int32 // 50
		var unknown047: Int32 // -25
		// 0xc0
		var unknown048: Int32 // -10
		var unknown049: Int32 // 30
		var unknown050: Int32 // 10
		var unknown051: Int32 // -65
		// 0xd0
		var unknown052: Int32 // -23
		var unknown053: Int32 // -21
		var unknown054: Int32 // -5
		var unknown055: Int32 // 24
		// 0xe0
		var unknown056: Int32 // -10
		var unknown057: Int32 // 30
		var unknown058: Int32 // -4
		var unknown059: Int32 // 22
		// 0xf0
		var unknown060: Int32 // 5
		var unknown061: Int32 // 24
		var unknown062: Int32 // 0
		var unknown063: Int32 // 24
		// 0x100
		var unknown064: Int32 // -2
		var unknown065: Int32 // 24
		var unknown066: Int32 // 0
		var unknown067: Int32 // 22
		// 0x110
		var unknown068: Int32 // 18
		var unknown069: Int32 // 24
		var unknown070: Int32 // 0
		var unknown071: Int32 // 30
		// 0x120
		var unknown072: Int32 // 6
		var unknown073: Int32 // 16
		var unknown074: Int32 // -10
		var unknown075: Int32 // 25
		// 0x130
		var unknown076: Int32 // 14
		var unknown077: Int32 // 30
		var unknown078: Int32 // 68
		var unknown079: Int32 // -70
		// 0x140
		var unknown080: Int32 // 8
		var unknown081: Int32 // 28
		var unknown082: Int32 // 0
		var unknown083: Int32 // 7
		
		// 0x150
		var unknownACount: UInt32
		var unknownAOffset: UInt32 = 0x1C4
		
		var unknownBCount: UInt32
		var unknownBOffset: UInt32
		
		// 0x160
		var unknownCCount: UInt32
		var unknownCOffset: UInt32
		
		var unknown084: Int32 // 1
		var unknown085: Int32 // 410
		// 0x170
		var unknown086: Int32 // 1
		var unknown087: Int32 // 60
		var unknown088: Int32 // 20
		var unknown089: Int32 // 1
		// 0x180
		var unknown090: Int32 // 144
		var unknown091: Int32 // 88
		var unknown092: Int32 // 112
		var unknown094: Int32 // 88
		// 0x190
		var unknown095: FixedPoint2012 // 16
		var unknown096: FixedPoint2012 // 1
		var unknown097: FixedPoint2012 // 2
		var unknown098: FixedPoint2012 // 0.2
		// 0x1a0
		var unknown099: Int32 // 128
		var unknown100: Int32 // 96
		
		var unknownDCount: UInt32
		var unknownDOffset: UInt32
		
		// 0x1b0
		var unknown101: Int32 // 257
		var unknown102: Int32 // 1
		var unknown103: Int32 // 16
		var unknown104: Int32 // 108
		// 0x1c0
		var unknown105: Int32 // 1
		
		@Count(givenBy: \Self.unknownACount)
		@Offset(givenBy: \Self.unknownAOffset)
		var unknownA: [Pair16]
		
		@Count(givenBy: \Self.unknownBCount)
		@Offset(givenBy: \Self.unknownBOffset)
		var unknownB: [Pair16]
		
		@Count(givenBy: \Self.unknownCCount)
		@Offset(givenBy: \Self.unknownCOffset)
		var unknownC: [Pair32]
		
		@Count(givenBy: \Self.unknownDCount)
		@Offset(givenBy: \Self.unknownDOffset)
		var unknownD: [Pair32]
		
		@BinaryConvertible
		struct Pair16 {
			var unknown1: FixedPoint88
			var unknown2: Int16
		}
		
		@BinaryConvertible
		struct Pair32 {
			var unknown1: Int32
			var unknown2: Int32
		}
	}
	
	struct Unpacked: Codable {
		var defaultHitRate: Double
		var hitRateDivisor: Double
		var minimumHitRate: Double
		
		var unknown004: Double
		var unknown005: Double
		
		var critDamageLowerBound: Double
		var critDamageUpperBound: Double
		
		var damageVarianceLowerBound: Double
		var damageVarianceUpperBound: Double
		
		var unknown010: Double
		var unknown011: Double
		
		var typeAdvantageMultiplier: Double
		var typeDisadvantageMultiplier: Double
		var typeNeutralMultiplier: Double
		
		var partingBlowAttackMultiplier: Double
		var partingBlowDefenseMultiplier: Double
		var partingBlowAccuracyMultiplier: Double
		var partingBlowSpeedMultiplier: Double
		var unknown019: Double
		
		var autoCounterFactor: Double
		
		var unknown021: Int32
		var unknown022: Int32
		var unknown023: Int32
		var unknown024: Int32
		var unknown025: Int32
		var unknown026: Int32
		var unknown027: Int32
		var unknown028: Int32
		var unknown029: Int32
		var unknown030: Int32
		var unknown031: Int32
		var unknown032: Int32
		var unknown033: Int32
		var unknown034: Int32
		var unknown035: Int32
		var unknown036: Int32
		var unknown037: Int32
		var unknown038: Int32
		var unknown039: Int32
		var unknown040: Int32
		var unknown041: Int32
		var unknown042: Int32
		var unknown043: Int32
		var unknown044: Int32
		var unknown045: Int32
		var unknown046: Int32
		var unknown047: Int32
		var unknown048: Int32
		var unknown049: Int32
		var unknown050: Int32
		var unknown051: Int32
		var unknown052: Int32
		var unknown053: Int32
		var unknown054: Int32
		var unknown055: Int32
		var unknown056: Int32
		var unknown057: Int32
		var unknown058: Int32
		var unknown059: Int32
		var unknown060: Int32
		var unknown061: Int32
		var unknown062: Int32
		var unknown063: Int32
		var unknown064: Int32
		var unknown065: Int32
		var unknown066: Int32
		var unknown067: Int32
		var unknown068: Int32
		var unknown069: Int32
		var unknown070: Int32
		var unknown071: Int32
		var unknown072: Int32
		var unknown073: Int32
		var unknown074: Int32
		var unknown075: Int32
		var unknown076: Int32
		var unknown077: Int32
		var unknown078: Int32
		var unknown079: Int32
		var unknown080: Int32
		var unknown081: Int32
		var unknown082: Int32
		var unknown083: Int32
		
		var unknown084: Int32
		var unknown085: Int32
		var unknown086: Int32
		var unknown087: Int32
		var unknown088: Int32
		var unknown089: Int32
		var unknown090: Int32
		var unknown091: Int32
		var unknown092: Int32
		var unknown094: Int32
		
		var unknown095: Double
		var unknown096: Double
		var unknown097: Double
		var unknown098: Double
		
		var unknown099: Int32
		var unknown100: Int32
		var unknown101: Int32
		var unknown102: Int32
		var unknown103: Int32
		var unknown104: Int32
		var unknown105: Int32
		
		var unknownA: [Pair16]
		
		var unknownB: [Pair16]
		
		var unknownC: [Pair32]
		
		var unknownD: [Pair32]
		
		struct Pair16: Codable {
			var unknown1: Double
			var unknown2: Int16
		}
		
		struct Pair32: Codable {
			var unknown1: Int32
			var unknown2: Int32
		}
	}
}

// MARK: packed
extension DBA.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> DBA.Unpacked {
		DBA.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: DBA.Unpacked, configuration: Configuration) {
		defaultHitRate = FixedPoint2012(unpacked.defaultHitRate)
		hitRateDivisor = FixedPoint2012(unpacked.hitRateDivisor)
		minimumHitRate = FixedPoint2012(unpacked.minimumHitRate)
		
		unknown004 = FixedPoint2012(unpacked.unknown004)
		unknown005 = FixedPoint2012(unpacked.unknown005)
		
		critDamageLowerBound = FixedPoint2012(unpacked.critDamageLowerBound)
		critDamageUpperBound = FixedPoint2012(unpacked.critDamageUpperBound)
		
		damageVarianceLowerBound = FixedPoint2012(unpacked.damageVarianceLowerBound)
		damageVarianceUpperBound = FixedPoint2012(unpacked.damageVarianceUpperBound)
		
		unknown010 = FixedPoint2012(unpacked.unknown010)
		unknown011 = FixedPoint2012(unpacked.unknown011)
		
		typeAdvantageMultiplier = FixedPoint2012(unpacked.typeAdvantageMultiplier)
		typeDisadvantageMultiplier = FixedPoint2012(unpacked.typeDisadvantageMultiplier)
		typeNeutralMultiplier = FixedPoint2012(unpacked.typeNeutralMultiplier)
		
		partingBlowAttackMultiplier = FixedPoint2012(unpacked.partingBlowAttackMultiplier)
		partingBlowDefenseMultiplier = FixedPoint2012(unpacked.partingBlowDefenseMultiplier)
		partingBlowAccuracyMultiplier = FixedPoint2012(unpacked.partingBlowAccuracyMultiplier)
		partingBlowSpeedMultiplier = FixedPoint2012(unpacked.partingBlowSpeedMultiplier)
		
		unknown019 = FixedPoint2012(unpacked.unknown019)
		
		autoCounterFactor = FixedPoint2012(unpacked.autoCounterFactor)
		
		unknown021 = unpacked.unknown021
		unknown022 = unpacked.unknown022
		unknown023 = unpacked.unknown023
		unknown024 = unpacked.unknown024
		unknown025 = unpacked.unknown025
		unknown026 = unpacked.unknown026
		unknown027 = unpacked.unknown027
		unknown028 = unpacked.unknown028
		unknown029 = unpacked.unknown029
		unknown030 = unpacked.unknown030
		unknown031 = unpacked.unknown031
		unknown032 = unpacked.unknown032
		unknown033 = unpacked.unknown033
		unknown034 = unpacked.unknown034
		unknown035 = unpacked.unknown035
		unknown036 = unpacked.unknown036
		unknown037 = unpacked.unknown037
		unknown038 = unpacked.unknown038
		unknown039 = unpacked.unknown039
		unknown040 = unpacked.unknown040
		unknown041 = unpacked.unknown041
		unknown042 = unpacked.unknown042
		unknown043 = unpacked.unknown043
		unknown044 = unpacked.unknown044
		unknown045 = unpacked.unknown045
		unknown046 = unpacked.unknown046
		unknown047 = unpacked.unknown047
		unknown048 = unpacked.unknown048
		unknown049 = unpacked.unknown049
		unknown050 = unpacked.unknown050
		unknown051 = unpacked.unknown051
		unknown052 = unpacked.unknown052
		unknown053 = unpacked.unknown053
		unknown054 = unpacked.unknown054
		unknown055 = unpacked.unknown055
		unknown056 = unpacked.unknown056
		unknown057 = unpacked.unknown057
		unknown058 = unpacked.unknown058
		unknown059 = unpacked.unknown059
		unknown060 = unpacked.unknown060
		unknown061 = unpacked.unknown061
		unknown062 = unpacked.unknown062
		unknown063 = unpacked.unknown063
		unknown064 = unpacked.unknown064
		unknown065 = unpacked.unknown065
		unknown066 = unpacked.unknown066
		unknown067 = unpacked.unknown067
		unknown068 = unpacked.unknown068
		unknown069 = unpacked.unknown069
		unknown070 = unpacked.unknown070
		unknown071 = unpacked.unknown071
		unknown072 = unpacked.unknown072
		unknown073 = unpacked.unknown073
		unknown074 = unpacked.unknown074
		unknown075 = unpacked.unknown075
		unknown076 = unpacked.unknown076
		unknown077 = unpacked.unknown077
		unknown078 = unpacked.unknown078
		unknown079 = unpacked.unknown079
		unknown080 = unpacked.unknown080
		unknown081 = unpacked.unknown081
		unknown082 = unpacked.unknown082
		unknown083 = unpacked.unknown083
		
		unknownACount = UInt32(unpacked.unknownA.count)
		
		unknownBCount = UInt32(unpacked.unknownB.count)
		unknownBOffset = unknownAOffset + unknownACount * 4
		
		unknownCCount = UInt32(unpacked.unknownC.count)
		unknownCOffset = unknownBOffset + unknownBCount * 4
		
		unknown084 = unpacked.unknown084
		unknown085 = unpacked.unknown085
		unknown086 = unpacked.unknown086
		unknown087 = unpacked.unknown087
		unknown088 = unpacked.unknown088
		unknown089 = unpacked.unknown089
		unknown090 = unpacked.unknown090
		unknown091 = unpacked.unknown091
		unknown092 = unpacked.unknown092
		unknown094 = unpacked.unknown094
		
		unknown095 = FixedPoint2012(unpacked.unknown095)
		unknown096 = FixedPoint2012(unpacked.unknown096)
		unknown097 = FixedPoint2012(unpacked.unknown097)
		unknown098 = FixedPoint2012(unpacked.unknown098)
		
		unknown099 = unpacked.unknown099
		unknown100 = unpacked.unknown100
		unknown101 = unpacked.unknown101
		unknown102 = unpacked.unknown102
		unknown103 = unpacked.unknown103
		unknown104 = unpacked.unknown104
		unknown105 = unpacked.unknown105
		
		unknownDCount = UInt32(unpacked.unknownD.count)
		unknownDOffset = unknownCOffset + unknownCCount * 8
		
		unknownA = unpacked.unknownA.map(Pair16.init)
		
		unknownB = unpacked.unknownB.map(Pair16.init)
		
		unknownC = unpacked.unknownC.map(Pair32.init)
		
		unknownD = unpacked.unknownD.map(Pair32.init)
	}
}

extension DBA.Packed.Pair16 {
	fileprivate init(_ unpacked: DBA.Unpacked.Pair16) {
		unknown1 = FixedPoint88(unpacked.unknown1)
		unknown2 = unpacked.unknown2
	}
}

extension DBA.Packed.Pair32 {
	fileprivate init(_ unpacked: DBA.Unpacked.Pair32) {
		unknown1 = unpacked.unknown1
		unknown2 = unpacked.unknown2
	}
}


// MARK: unpacked
extension DBA.Unpacked: ProprietaryFileData {
	static let fileExtension = ".dba.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: Configuration) -> DBA.Packed {
		DBA.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: DBA.Packed, configuration: Configuration) {
		defaultHitRate = Double(packed.defaultHitRate)
		hitRateDivisor = Double(packed.hitRateDivisor)
		minimumHitRate = Double(packed.minimumHitRate)
		
		unknown004 = Double(packed.unknown004)
		unknown005 = Double(packed.unknown005)
		
		critDamageLowerBound = Double(packed.critDamageLowerBound)
		critDamageUpperBound = Double(packed.critDamageUpperBound)
		
		damageVarianceLowerBound = Double(packed.damageVarianceLowerBound)
		damageVarianceUpperBound = Double(packed.damageVarianceUpperBound)
		
		unknown010 = Double(packed.unknown010)
		unknown011 = Double(packed.unknown011)
		
		typeAdvantageMultiplier = Double(packed.typeAdvantageMultiplier)
		typeDisadvantageMultiplier = Double(packed.typeDisadvantageMultiplier)
		typeNeutralMultiplier = Double(packed.typeNeutralMultiplier)
		
		partingBlowAttackMultiplier = Double(packed.partingBlowAttackMultiplier)
		partingBlowDefenseMultiplier = Double(packed.partingBlowDefenseMultiplier)
		partingBlowAccuracyMultiplier = Double(packed.partingBlowAccuracyMultiplier)
		partingBlowSpeedMultiplier = Double(packed.partingBlowSpeedMultiplier)
		unknown019 = Double(packed.unknown019)
		
		autoCounterFactor = Double(packed.autoCounterFactor)
		
		unknown021 = packed.unknown021
		unknown022 = packed.unknown022
		unknown023 = packed.unknown023
		unknown024 = packed.unknown024
		unknown025 = packed.unknown025
		unknown026 = packed.unknown026
		unknown027 = packed.unknown027
		unknown028 = packed.unknown028
		unknown029 = packed.unknown029
		unknown030 = packed.unknown030
		unknown031 = packed.unknown031
		unknown032 = packed.unknown032
		unknown033 = packed.unknown033
		unknown034 = packed.unknown034
		unknown035 = packed.unknown035
		unknown036 = packed.unknown036
		unknown037 = packed.unknown037
		unknown038 = packed.unknown038
		unknown039 = packed.unknown039
		unknown040 = packed.unknown040
		unknown041 = packed.unknown041
		unknown042 = packed.unknown042
		unknown043 = packed.unknown043
		unknown044 = packed.unknown044
		unknown045 = packed.unknown045
		unknown046 = packed.unknown046
		unknown047 = packed.unknown047
		unknown048 = packed.unknown048
		unknown049 = packed.unknown049
		unknown050 = packed.unknown050
		unknown051 = packed.unknown051
		unknown052 = packed.unknown052
		unknown053 = packed.unknown053
		unknown054 = packed.unknown054
		unknown055 = packed.unknown055
		unknown056 = packed.unknown056
		unknown057 = packed.unknown057
		unknown058 = packed.unknown058
		unknown059 = packed.unknown059
		unknown060 = packed.unknown060
		unknown061 = packed.unknown061
		unknown062 = packed.unknown062
		unknown063 = packed.unknown063
		unknown064 = packed.unknown064
		unknown065 = packed.unknown065
		unknown066 = packed.unknown066
		unknown067 = packed.unknown067
		unknown068 = packed.unknown068
		unknown069 = packed.unknown069
		unknown070 = packed.unknown070
		unknown071 = packed.unknown071
		unknown072 = packed.unknown072
		unknown073 = packed.unknown073
		unknown074 = packed.unknown074
		unknown075 = packed.unknown075
		unknown076 = packed.unknown076
		unknown077 = packed.unknown077
		unknown078 = packed.unknown078
		unknown079 = packed.unknown079
		unknown080 = packed.unknown080
		unknown081 = packed.unknown081
		unknown082 = packed.unknown082
		unknown083 = packed.unknown083
		
		unknown084 = packed.unknown084
		unknown085 = packed.unknown085
		unknown086 = packed.unknown086
		unknown087 = packed.unknown087
		unknown088 = packed.unknown088
		unknown089 = packed.unknown089
		unknown090 = packed.unknown090
		unknown091 = packed.unknown091
		unknown092 = packed.unknown092
		unknown094 = packed.unknown094
		
		unknown095 = Double(packed.unknown095)
		unknown096 = Double(packed.unknown096)
		unknown097 = Double(packed.unknown097)
		unknown098 = Double(packed.unknown098)
		
		unknown099 = packed.unknown099
		unknown100 = packed.unknown100
		unknown101 = packed.unknown101
		unknown102 = packed.unknown102
		unknown103 = packed.unknown103
		unknown104 = packed.unknown104
		unknown105 = packed.unknown105
		
		unknownA = packed.unknownA.map(Pair16.init)
		
		unknownB = packed.unknownB.map(Pair16.init)
		
		unknownC = packed.unknownC.map(Pair32.init)
		
		unknownD = packed.unknownD.map(Pair32.init)
	}
}

extension DBA.Unpacked.Pair16 {
	fileprivate init(_ packed: DBA.Packed.Pair16) {
		unknown1 = Double(packed.unknown1)
		unknown2 = packed.unknown2
	}
}

extension DBA.Unpacked.Pair32 {
	fileprivate init(_ packed: DBA.Packed.Pair32) {
		unknown1 = packed.unknown1
		unknown2 = packed.unknown2
	}
}
