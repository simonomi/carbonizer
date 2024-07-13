import BinaryParser

@BinaryConvertible
struct SpriteBitmap {
	var widthAndHeight: UInt8
	var pixelCount: UInt8 // times 64
	var colorPaletteType: SpritePalette.ColorPaletteType
	
	@If(\Self.colorPaletteType, is: .equalTo(.sixteenColors))
	@Padding(bytes: 1)
	@Count(givenBy: \Self.pixelCount, .times(32)) // times 64 but each pixel is 4 bits
	var colorsIndexes16: [UInt8]?
	
	@If(\Self.colorPaletteType, is: .equalTo(.twoFiftySixColors))
	@Padding(bytes: 1)
	@Count(givenBy: \Self.pixelCount, .times(64))
	var colorsIndexes256: [UInt8]?
}

extension SpriteBitmap {
	var width: Int32 {
		switch widthAndHeight {
			case 0, 2, 6: 8
			case 1, 4, 10: 16
			case 5, 8, 9, 14: 32
			case 12, 13: 64
			default: fatalError("unreachable") // TODO: handle errors properly
		}
	}
	
	var height: Int32 {
		switch widthAndHeight {
			case 0, 1, 5: 8
			case 2, 4, 9: 16
			case 6, 8, 10, 13: 32
			case 12, 14: 64
			default: fatalError("unreachable") // TODO: handle errors properly
		}
	}
	
	// NOTE: this uses position as the anchor of the top left, not bottom left
	func write(
		to bitmap: inout Bitmap,
		with palette: SpritePalette,
		at position: Point<Int16>
	) {
		let contents =
			switch colorPaletteType {
				case .sixteenColors:
					colorsIndexes16!.flatMap {[
						// color 0 is transparent, which is indicated by nil
						$0 & 0b1111 == 0 ? nil : palette.colors[Int($0 & 0b1111)],
						$0 >> 4 == 0 ? nil : palette.colors[Int($0 >> 4)]
					]}
				case .twoFiftySixColors:
					colorsIndexes256!.map {
						// color 0 is transparent, which is indicated by nil
						$0 == 0 ? nil : palette.colors[Int($0)]
					}
			}
		
		let xOffset = Int(position.x)
		let yOffset = Int(position.y)
		
		let gridSize = 8
		
		var bitmapIndex = 0
		var gridX = 0
		var gridY = 0
		
		while bitmapIndex < contents.count {
			for y in 0..<gridSize {
				for x in 0..<gridSize {
					if contents[bitmapIndex] != nil {
						bitmap.contents[
							x: x + gridX * gridSize + xOffset,
							y: y + gridY * gridSize + yOffset,
							width: Int(bitmap.width)
						] = contents[bitmapIndex]
					}
					bitmapIndex += 1
				}
			}
			
			gridX += 1
			
			if (gridX >= Int(width) / gridSize) {
				gridX = 0
				gridY += 1
			}
		}
	}
	
	func toBitmap(with palette: SpritePalette) -> Bitmap {
		let contents =
			switch colorPaletteType {
				case .sixteenColors:
					colorsIndexes16!.flatMap {[
						// color 0 is transparent, which is indicated by nil
						$0 & 0b1111 == 0 ? nil : palette.colors[Int($0 & 0b1111)],
						$0 >> 4 == 0 ? nil : palette.colors[Int($0 >> 4)]
					]}
				case .twoFiftySixColors:
					colorsIndexes256!.map {
						// color 0 is transparent, which is indicated by nil
						$0 == 0 ? nil : palette.colors[Int($0)]
					}
			}
		
		let gridSize = 8
		
		var bitmapIndex = 0
		var gridX = 0
		var gridY = 0
		
		var gridContents = [RGB555Color?](repeating: nil, count: contents.count)
		
		while bitmapIndex < contents.count {
			for y in 0..<gridSize {
				for x in 0..<gridSize {
					gridContents[
						x: x + gridX * gridSize,
						y: y + gridY * gridSize,
						width: Int(width)
					] = contents[bitmapIndex]
					bitmapIndex += 1
				}
			}
			
			gridX += 1
			
			if (gridX >= Int(width) / gridSize) {
				gridX = 0
				gridY += 1
			}
		}
		
		return Bitmap(width: width, height: height, contents: gridContents)
	}
}
