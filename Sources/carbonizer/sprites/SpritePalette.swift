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
}
