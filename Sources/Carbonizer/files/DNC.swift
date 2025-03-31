import BinaryParser

struct DNC {
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "DNC"
		
		var unknown1: UInt32
		var unknown2: UInt32 = 0x3C // 60
		
		var firstCount: UInt32
		var firstOffset: UInt32 = 0x24
		
		var secondCount: UInt32
		var secondOffset: UInt32
		
		var thirdCount: UInt32
		var thirdOffset: UInt32
		
		@Count(givenBy: \Self.firstCount)
		@Offset(givenBy: \Self.firstOffset)
		var firsts: [UInt32]
		
		@Count(givenBy: \Self.secondCount)
		@Offset(givenBy: \Self.secondOffset)
		var seconds: [Second]
		
		@Count(givenBy: \Self.thirdCount)
		@Offset(givenBy: \Self.thirdOffset)
		var thirds: [Third]
		
		@BinaryConvertible
		struct Second {
			var unknown1: UInt32
			var unknown2: UInt32
			var unknown3: UInt32
		}
		
		@BinaryConvertible
		struct Third {
			var unknown1: UInt32
			var unknown2: UInt32
		}
	}
}
