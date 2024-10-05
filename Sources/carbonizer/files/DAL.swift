import BinaryParser

struct DAL {
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "DAL"
		var unknown1: UInt32 = 0x659
		var unknown2: UInt32 = 0x7f4
		var indicesCount: UInt32
		var indicesOffset: UInt32
		@Count(givenBy: \Self.indicesCount)
		@Offset(givenBy: \Self.indicesOffset)
		var indices: [UInt32]
		@Offsets(givenBy: \Self.indices)
		var attacks: [Attack]
		
		// see https://github.com/opiter09/Fossil-Fighters-Documentation/blob/main/FF1/Attack_Defs.txt
		@BinaryConvertible
		struct Attack {
			var id: UInt32
			var numberOfHits: UInt32
			var hitDamagesOffset: UInt32 = 0x20
			var totalDamageOffset: UInt32
			var primaryStatusDataOffset: UInt32
			var secondaryStatusDataOffset: UInt32
			var counterProof: UInt32 // 0 for counter-proof, 3 for not
			@Count(givenBy: \Self.numberOfHits)
			@Offset(givenBy: \Self.hitDamagesOffset)
			var hitDamages: [Damage]
			@Offset(givenBy: \Self.totalDamageOffset)
			var totalDamage: Damage
			@Offset(givenBy: \Self.primaryStatusDataOffset)
			var primaryEffect: PrimaryEffect
			@Offset(givenBy: \Self.secondaryStatusDataOffset)
			var secondaryEffect: SecondaryEffect
			
			@BinaryConvertible
			struct Damage {
				var fp: UInt16
				var damage: UInt16
			}
			
			@BinaryConvertible
			struct PrimaryEffect {
				var effectCode: UInt8
				var chanceToHit: UInt8
				var turnCount: UInt8
				var icon: UInt8
				var dependsOnEffect1: UInt8
				var dependsOnEffect2: UInt8
			}
			
			@BinaryConvertible
			struct SecondaryEffect {
				var effectCode: UInt8
				var chanceToHit: UInt8
				var dependsOnEffect: UInt16
				@If(\Self.effect, is: .equalTo(.transformation))
				var transformation: Transformation?
				
				@BinaryConvertible
				struct Transformation {
					var vivosaursCount: UInt32
					var vivosaursOffset: UInt32 = 0xC
					@Count(givenBy: \Self.vivosaursCount)
					@Offset(givenBy: \Self.vivosaursOffset, .plus(0x4)) // relative to SecondaryEffect
					var vivosaurs: [UInt8]
					// NOTE: plus padding to make this 4-byte aligned
				}
			}
		}
	}
}
