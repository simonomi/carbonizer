import BinaryParser

struct DBS {
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "DBS"
		
		var unknown1: UInt32
		var unknown2: UInt32
		
		var music: UInt32 // 0xC
		
		var unknown3: UInt32
		var unknown4: UInt32
		var unknown5: UInt32
		var unknown6: UInt32
		
		var unknown7: UInt32
		var unknown8: UInt32
		var unknown9: UInt32
		var unknown10: UInt32
		
		var arena: UInt32 // 0x30
		var unknown11: UInt32
		var unknown12: UInt32
		var unknown13: UInt32
		
	}
}
