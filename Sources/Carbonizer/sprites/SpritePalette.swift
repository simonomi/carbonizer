import BinaryParser

@BinaryConvertible
struct SpritePalette {
	var colorPaletteType: ColorPaletteType
	@Padding(bytes: 3)
	@Count(givenBy: \Self.colorPaletteType.count)
	var colors: [Color555]
	
	enum ColorPaletteType: UInt8, Codable, RawRepresentable {
		case sixteenColors, twoFiftySixColors
		
		var count: Int {
			switch self {
				case .sixteenColors: 16
				case .twoFiftySixColors: 256
			}
		}
	}
}
