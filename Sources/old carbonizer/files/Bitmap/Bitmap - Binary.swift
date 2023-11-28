//
//  File.swift
//  
//
//  Created by simon pellerin on 2023-06-27.
//

import Foundation

extension BitmapFile {
	enum TextureFormat: UInt8 {
		case a3i5 = 1, twoBits, fourBits, eightBits, compressed, a5i3, direct
	}
	
	init(
		name: String,
		width: Int32,
		height: Int32,
		type: TextureFormat,
		palette inputPaletteData: Data,
		pixels: Data
	) throws {
		self.name = name
		self.width = width
		self.height = height
		
		let paletteData = Datastream(inputPaletteData)
		let numberOfPalettes = inputPaletteData.count / 2
		let palette = try (0 ..< numberOfPalettes).map { _ in
			try paletteData.read(UInt16.self)
		}.map { Color(rgb555: $0) }
		
		switch type {
			case .twoBits:
				contents = getTwoBitBitmap(from: pixels, using: palette)
			case .fourBits:
				contents = getFourBitBitmap(from: pixels, using: palette)
			case .eightBits:
				contents = getEightBitBitmap(from: pixels, using: palette)
			case .a3i5:
				contents = getA3i5Bitmap(from: pixels, using: palette)
			case .a5i3:
				contents = getA5i3Bitmap(from: pixels, using: palette)
			case .direct:
				contents = try getDirectBitmap(from: pixels)
			case .compressed:
				fatalError("i dont wanna do 4x4 compressed texture format")
		}
	}
}
	
fileprivate func getTwoBitBitmap(from pixelData: Data, using palette: [BitmapFile.Color]) -> [BitmapFile.Color] {
	getBitmap(
		from: pixelData.flatMap {[
			$0 & 0b11,
			$0 >> 2 & 0b11,
			$0 >> 4 & 0b11,
			$0 >> 6
		]},
		using: palette
	)
}

fileprivate func getFourBitBitmap(from pixelData: Data, using palette: [BitmapFile.Color]) -> [BitmapFile.Color] {
	getBitmap(
		from: pixelData.flatMap {[
			$0 & 0b1111,
			$0 >> 4
		]},
		using: palette
	)
}

fileprivate func getEightBitBitmap(from pixelData: Data, using palette: [BitmapFile.Color]) -> [BitmapFile.Color] {
	getBitmap(from: [UInt8](pixelData), using: palette)
}

fileprivate func getBitmap(from bytes: [UInt8], using palette: [BitmapFile.Color]) -> [BitmapFile.Color] {
	bytes.map { palette.element(at: Int($0)) ?? .white }
}

fileprivate func getA3i5Bitmap(from pixelData: Data, using palette: [BitmapFile.Color]) -> [BitmapFile.Color] {
	pixelData
		.map {(
			index: $0 & 0b11111,
			alpha: $0 >> 5
		)}
		.map {
			var color = palette[Int($0.index)]
			color.alpha = Double($0.alpha) / 7
			return color
		}
}
 
fileprivate func getA5i3Bitmap(from pixelData: Data, using palette: [BitmapFile.Color]) -> [BitmapFile.Color] {
	pixelData
		.map {(
			index: $0 & 0b111,
			alpha: $0 >> 3
		)}
		.map {
			var color = palette[Int($0.index)]
			color.alpha = Double($0.alpha) / 31
			return color
		}
}

fileprivate func getDirectBitmap(from inputPixelData: Data) throws -> [BitmapFile.Color] {
	let pixelData = Datastream(inputPixelData)
	let numberOfPixels = inputPixelData.count / 2
	return try (0 ..< numberOfPixels).map { _ in
		BitmapFile.Color(rgb555: try pixelData.read(UInt16.self))
	}
}

extension BitmapFile.Color {
	init(rgb555: UInt16, alpha: Double = 1) {
		red = Double(rgb555 & 0b11111) / 0b11111
		green = Double(rgb555 >> 5 & 0b11111) / 0b11111
		blue = Double(rgb555 >> 10 & 0b11111) / 0b11111
		self.alpha = alpha
	}
	
	func write(to data: Datawriter) {
		data.write(UInt8(red * 255))
		data.write(UInt8(green * 255))
		data.write(UInt8(blue * 255))
		data.write(UInt8(alpha * 255))
	}
	
	func writeWithoutTransparency(to data: Datawriter) {
		let rgb555 = (
			UInt16(blue * 31) |
			UInt16(green * 31) << 5 |
			UInt16(red * 31) << 10
		)
		
		data.write(rgb555)
	}
	
	static let white = BitmapFile.Color(red: 1, green: 1, blue: 1, alpha: 1)
}

extension Data {
	init(from bitmap: BitmapFile) throws {
		let output = Datawriter()
		
		let fileHeaderLength: UInt32 = 14
		let infoHeaderLength: UInt32 = 108
		let bitmapLength = UInt32(bitmap.contents.count) * 4
		
		try output.write("BM")
		output.write(fileHeaderLength + infoHeaderLength + bitmapLength) // file size
		output.seek(bytes: 4) // reserved
		output.write(fileHeaderLength + infoHeaderLength) // offset to bitmap
		
		output.write(infoHeaderLength)
		output.write(bitmap.width)
		output.write(-bitmap.height)
		output.write(UInt16(1)) // planes
		output.write(UInt16(32)) // bits per pixel
		output.write(UInt32(3)) // compression (BITFIELDS)
		output.write(bitmapLength)
		output.write(UInt32(0x500)) // px/m (x)
		output.write(UInt32(0x500)) // px/m (y)
		output.write(UInt32.zero) // colors used (all)
		output.write(UInt32.zero) // colors important (all)
		output.write(UInt32(0x000000FF)) // red mask
		output.write(UInt32(0x0000FF00)) // green mask
		output.write(UInt32(0x00FF0000)) // blue mask
		output.write(UInt32(0xFF000000)) // alpha mask
		
		try output.writeCString("Win ") // color space (default)
		output.seek(bytes: -1)
		
		output.seek(bytes: 36) // endpoints (unused)
		output.seek(bytes: 12) // response curves (unused)
		
		bitmap.contents.forEach { $0.write(to: output) }
		
		self = output.data
	}
	
	init(withoutTransparencyFrom bitmap: BitmapFile) throws {
		let output = Datawriter()
		
		let fileHeaderLength: UInt32 = 14
		let infoHeaderLength: UInt32 = 40
		let bitmapLength = UInt32(bitmap.contents.count) * 16
		
		try output.write("BM")
		output.write(fileHeaderLength + infoHeaderLength + bitmapLength) // file size
		output.seek(bytes: 4) // reserved
		output.write(fileHeaderLength + infoHeaderLength) // offset to bitmap
		
		output.write(infoHeaderLength)
		output.write(bitmap.width)
		output.write(-bitmap.height)
		output.write(UInt16(1)) // planes
		output.write(UInt16(16)) // bits per pixel
		output.write(UInt32.zero) // compression (RGB)
		output.write(UInt32.zero) // decompressed size (zero, not compressed)
		output.write(UInt32(0x500)) // p/m (x)
		output.write(UInt32(0x500)) // p/m (y)
		output.write(UInt32.zero) // colors used (all)
		output.write(UInt32.zero) // colors important (all)
		
		bitmap.contents.forEach { $0.writeWithoutTransparency(to: output) }
		
		self = output.data
	}
}
