import BinaryParser

struct MAP {
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "MAP"
		
		var offset1: UInt32 = 0x6C
		var offset2: UInt32
		
		var unknown1: UInt32
		var unknown2: UInt32
		var unknown3: UInt32
		var unknown4: UInt32
		var unknown5: UInt32
		var unknown6: UInt32
		var unknown7: UInt32
		var unknown8: UInt32
		var unknown9: UInt32
		var unknown10: UInt32
		var unknown11: UInt32
		var unknown12: UInt32
		var unknown13: UInt32
		var unknown14: UInt32
		var unknown15: UInt32
		var unknown16: UInt32
		var unknown17: UInt32
		var unknown18: UInt32
		var unknown19: UInt32
		var unknown20: UInt32
		var unknown21: UInt32
		var unknown22: UInt32
		var unknown23: UInt32
		var unknown24: UInt32
		
		
	}
}
