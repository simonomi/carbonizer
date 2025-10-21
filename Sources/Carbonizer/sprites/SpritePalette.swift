import BinaryParser

enum SpritePalette {
	@BinaryConvertible
	struct Packed {
		var type: MMS.Packed.ColorPaletteType
		@Padding(bytes: 3)
		@Count(givenBy: \Self.type.colorCount)
		var colors: [Color555]
	}
	
	struct Unpacked: Codable {
		var type: MMS.Unpacked.ColorPaletteType
		var colors: [Color]
	}
}

extension MMS.Packed.ColorPaletteType {
	var colorCount: Int {
		switch self {
			case .sixteenColors: 16
			case .twoFiftySixColors: 256
		}
	}
}

// MARK: packed
extension SpritePalette.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> SpritePalette.Unpacked {
		SpritePalette.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: SpritePalette.Unpacked, configuration: Configuration) {
		type = MMS.Packed.ColorPaletteType(unpacked.type)
		colors = unpacked.colors.map(Color555.init)
	}
}

// MARK: unpacked
extension SpritePalette.Unpacked: ProprietaryFileData {
	static let fileExtension = ".spritePalette.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: Configuration) -> SpritePalette.Packed {
		SpritePalette.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: SpritePalette.Packed, configuration: Configuration) {
		type = MMS.Unpacked.ColorPaletteType(packed.type)
		colors = packed.colors.map(Color.init)
	}
}
