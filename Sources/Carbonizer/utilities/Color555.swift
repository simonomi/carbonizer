import BinaryParser

@BinaryConvertible
struct Color555 {
	var raw: UInt16
	
	var red: UInt8 {
		UInt8(raw & 0b11111)
	}
	
	var green: UInt8 {
		UInt8(raw >> 5 & 0b11111)
	}
	
	var blue: UInt8 {
		UInt8(raw >> 10 & 0b11111)
	}
}

extension Color555 {
	init(_ color: Color) {
		func fiveBit(_ color: UInt8) -> UInt16 {
			// 8 is the ratio between the number of colors in each (256:32)
			UInt16(color / 8)
		}
		
		raw = fiveBit(color.red) |
		(fiveBit(color.green) << 5) |
		(fiveBit(color.blue) << 10)
	}
}
