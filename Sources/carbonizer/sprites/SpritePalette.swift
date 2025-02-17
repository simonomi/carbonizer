import BinaryParser

@BinaryConvertible
struct SpritePalette {
	var colorPaletteType: ColorPaletteType
	@Padding(bytes: 3)
	@Count(givenBy: \Self.colorPaletteType.count)
	var colors: [RGB555Color]
	
	enum ColorPaletteType: UInt8, BinaryConvertible, Codable {
		case sixteenColors, twoFiftySixColors
		
		var count: Int {
			switch self {
				case .sixteenColors: 16
				case .twoFiftySixColors: 256
			}
		}
		
		enum InvalidType: Error {
			case invalidColorPaletteType(UInt8)
		}
		
		init(_ data: Datastream) throws {
			let rawByte = try data.read(UInt8.self)
			guard let type = Self(rawValue: rawByte) else {
				throw InvalidType.invalidColorPaletteType(rawByte)
			}
			self = type
		}
		
		func write(to data: BinaryParser.Datawriter) {
			data.write(rawValue)
		}
	}
	
	consuming func colorOrderSwapped() -> Self {
		colors = colors.map {
			let red = $0.raw & 0b11111
			let green = $0.raw >> 5 & 0b11111
			let blue = $0.raw >> 10 & 0b11111
			
			return RGB555Color(raw: red << 10 | green << 5 | blue)
		}
		return self
	}
}
