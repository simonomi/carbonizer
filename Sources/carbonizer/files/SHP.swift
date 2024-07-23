import BinaryParser

struct SHP {
	@BinaryConvertible
	struct Binary {
		var magicBytes = "SHP"
		var firstCount: UInt32
		var firstOffset: UInt32
		var secondCount: UInt32
		var secondOffset: UInt32
		
		@Count(givenBy: \Self.firstCount)
		@Offset(givenBy: \Self.firstOffset)
		var firsts: [Entry]
		
		@Count(givenBy: \Self.secondCount)
		@Offset(givenBy: \Self.secondOffset)
		var seconds: [Entry]
		
		@BinaryConvertible
		struct Entry {
			var unknown1: UInt32 = 0
			var unknown2: UInt32
		}
	}
}
