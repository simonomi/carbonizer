// TODO: make this BinaryConvertible so no conversion is necessary when packing/unpacking?
struct Color: Codable {
	var red: UInt8
	var green: UInt8
	var blue: UInt8
	
	init(_ bytes: [UInt8]) {
		guard bytes.count == 3 else {
			todo("throw error")
		}
		
		red = bytes[0]
		green = bytes[1]
		blue = bytes[2]
	}
	
	init(_ rgb555: RGB555Color) {
		red = UInt8(rgb555.red * 255)
		green = UInt8(rgb555.green * 255)
		blue = UInt8(rgb555.blue * 255)
	}
	
	init(_ string: String) {
		guard string.count == 7, string.hasPrefix("#") else {
			todo("throw error")
		}
		
		guard let red = UInt8(string.dropFirst().prefix(2), radix: 16),
			  let green = UInt8(string.dropFirst(3).prefix(2), radix: 16),
			  let blue = UInt8(string.dropFirst(5).prefix(2), radix: 16)
		else {
			todo("throw error")
		}
		
		self.red = red
		self.green = green
		self.blue = blue
	}
	
	var hexCode: String {
		"#" +
		String(red, radix: 16).padded(toLength: 2, with: "0", from: .leading) +
		String(green, radix: 16).padded(toLength: 2, with: "0", from: .leading) +
		String(blue, radix: 16).padded(toLength: 2, with: "0", from: .leading)
	}
	
	var bytes: [UInt8] {
		[red, green, blue]
	}
	
	init(from decoder: any Decoder) throws {
		self = Self(try String(from: decoder))
	}
	
	func encode(to encoder: any Encoder) throws {
		try hexCode.encode(to: encoder)
	}
}
