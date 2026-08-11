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
	
	init(_ rgb555: Color555) {
		// * 8 doesn't map the entire range, it misses the highest 7 output values
		red = UInt8(UInt(rgb555.red) * 255 / 31)
		green = UInt8(UInt(rgb555.green) * 255 / 31)
		blue = UInt8(UInt(rgb555.blue) * 255 / 31)
	}
	
	enum ParseError: Error, CustomStringConvertible {
		case wrongLength(String)
		case invalidHex(String)
		
		var description: String {
			switch self {
				case .wrongLength(let string):
					"invalid hex color: \(.red)'\(string)'\(.normal), must be a \(.green)#\(.normal) followed by 6 hex digits (for example: \(.green)#FFD800\(.normal))"
				case .invalidHex(let string):
					"invalid hex color: \(.red)'\(string)'\(.normal), only the digits \(.green)0–9 a–f A–F\(.normal) are allowed"
			}
		}
	}
	
	init(_ raw: String) throws(ParseError) {
		guard raw.count == 7, raw.hasPrefix("#") else {
			throw .wrongLength(raw)
		}
		
		guard let red = UInt8(raw.dropFirst().prefix(2), radix: 16),
			  let green = UInt8(raw.dropFirst(3).prefix(2), radix: 16),
			  let blue = UInt8(raw.dropFirst(5).prefix(2), radix: 16)
		else {
			throw .invalidHex(raw)
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
		self = try Self(String(from: decoder))
	}
	
	func encode(to encoder: any Encoder) throws {
		try hexCode.encode(to: encoder)
	}
}
