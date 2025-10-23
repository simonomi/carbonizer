import BinaryParser

enum SpriteBitmap {
	@BinaryConvertible
	struct Packed {
		var widthAndHeight: UInt8
		var pixelCountDividedBy64: UInt8
		var colorPaletteType: MMS.Packed.ColorPaletteType
		
		@If(\Self.colorPaletteType, is: .equalTo(.sixteenColors))
		@Padding(bytes: 1)
		@Count(givenBy: \Self.pixelCountDividedBy64, .times(32)) // times 64 but each pixel is 4 bits
		var colorIndices16: [UInt8]?
		
		@If(\Self.colorPaletteType, is: .equalTo(.twoFiftySixColors))
		@Padding(bytes: 1)
		@Count(givenBy: \Self.pixelCountDividedBy64, .times(64))
		var colorsIndices256: [UInt8]?
	}
	
	struct Unpacked: Codable {
		var width: UInt32
		var height: UInt32
		var colorPaletteType: MMS.Unpacked.ColorPaletteType
		var colorIndices: [UInt8]
	}
}

extension BMP {
	// this uses position as the anchor of the top left, not bottom left
	mutating func write(
		bitmap: SpriteBitmap.Unpacked,
		with palette: SpritePalette.Unpacked,
		at position: SpriteAnimation.Point<Int16>
	) {
		let xOffset = Int(position.x)
		let yOffset = Int(position.y)
		
		let gridSize = 8
		
		var bitmapIndex = 0
		var gridX = 0
		var gridY = 0
		
		let colors = palette.colors.map { BMP.Color($0) }
		
		while bitmapIndex < bitmap.colorIndices.count {
			for y in 0..<gridSize {
				for x in 0..<gridSize {
					let colorIndex = Int(bitmap.colorIndices[bitmapIndex])
					
					// color 0 is transparent
					if colorIndex != 0 {
						contents[
							x: x + gridX * gridSize + xOffset,
							y: y + gridY * gridSize + yOffset,
							width: Int(width)
						] = colors[colorIndex]
					}
					
					bitmapIndex += 1
				}
			}
			
			gridX += 1
			
			if (gridX >= Int(bitmap.width) / gridSize) {
				gridX = 0
				gridY += 1
			}
		}
	}
}

// MARK: packed
extension SpriteBitmap.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> SpriteBitmap.Unpacked {
		SpriteBitmap.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: SpriteBitmap.Unpacked, configuration: Configuration) {
		todo()
		
////		widthAndHeight =
//		
//		pixelCountDividedBy64 = UInt8(unpacked.colorIndices.count / 64)
//		
//		colorPaletteType = MMS.Packed.ColorPaletteType(unpacked.colorPaletteType)
//		
//		switch colorPaletteType {
//			case .sixteenColors:
////				colorIndices16 = unpacked.colorIndices // TODO: join 4-bit indices into 8-bit ones
//				colorsIndices256 = nil
//			case .twoFiftySixColors:
//				colorIndices16 = nil
//				colorsIndices256 = unpacked.colorIndices
//		}
	}
}

// MARK: unpacked
extension SpriteBitmap.Unpacked: ProprietaryFileData {
	static let fileExtension = ".spriteBitmap.json"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> SpriteBitmap.Packed {
		SpriteBitmap.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: SpriteBitmap.Packed, configuration: Configuration) {
		width = switch packed.widthAndHeight {
			case 0, 2, 6: 8
			case 1, 4, 10: 16
			case 5, 8, 9, 14: 32
			case 12, 13: 64
			default: todo("prohibited")
		}
		
		height = switch packed.widthAndHeight {
			case 0, 1, 5: 8
			case 2, 4, 9: 16
			case 6, 8, 10, 13: 32
			case 12, 14: 64
			default: todo("prohibited")
		}
		
		colorPaletteType = MMS.Unpacked.ColorPaletteType(packed.colorPaletteType)
		
		colorIndices = switch packed.colorPaletteType {
			case .sixteenColors:
				packed.colorIndices16!.flatMap { [$0 & 0b1111, $0 >> 4] }
			case .twoFiftySixColors:
				packed.colorsIndices256!
		}
	}
}
