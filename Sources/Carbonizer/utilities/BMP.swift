import BinaryParser
import Foundation

struct BMP {
	var width: UInt32
	var height: UInt32
	var contents: [Color]
	
	@BinaryConvertible
	struct Color {
		// BGRA bc blender ignores the header info and assumes its BGRA no matter what
		var blue: UInt8
		var green: UInt8
		var red: UInt8
		var alpha: UInt8
	}
}

extension BMP.Color {
	init(_ color: Color, alpha: Double = 1) {
		blue = color.blue
		green = color.green
		red = color.red
		self.alpha = UInt8(alpha * 255)
	}
	
	init(_ rgb555: Color555, alpha: Double = 1) {
		// 8 is the ratio between the number of colors in each (32:256)
		red = rgb555.red * 8
		green = rgb555.green * 8
		blue = rgb555.blue * 8
		self.alpha = UInt8(alpha * 255)
	}
	
	static let transparent = Self(blue: 0, green: 0, red: 0, alpha: 0)
	
	mutating func replaceAlpha(with newAlpha: Double) {
		alpha = UInt8(newAlpha * 255)
	}
	
	consuming func replacingAlpha(with newAlpha: Double) -> Self {
		replaceAlpha(with: newAlpha)
		return self
	}
}

extension BMP: BinaryConvertible {
	init(_ data: Datastream) throws {
		fatalError("cannot read bmp file")
	}
	
	func write(to data: Datawriter) {
		let fileHeaderLength: UInt32 = 14
		let infoHeaderLength: UInt32 = 108
		let bitmapLength = UInt32(contents.count) * 4
		
		data.write("BM", length: 2)
		data.write(fileHeaderLength + infoHeaderLength + bitmapLength) // file size
		data.jump(bytes: 4) // reserved
		data.write(fileHeaderLength + infoHeaderLength) // offset to bitmap
		
		data.write(infoHeaderLength)
		data.write(width)
		data.write(-Int32(height))
		data.write(UInt16(1)) // planes
		data.write(UInt16(32)) // bits per pixel
		data.write(UInt32(3)) // compression (BITFIELDS)
		data.write(bitmapLength)
		data.write(UInt32(0x500)) // px/m (x)
		data.write(UInt32(0x500)) // px/m (y)
		data.write(UInt32.zero) // colors used (all)
		data.write(UInt32.zero) // colors important (all)
		data.write(UInt32(0x00FF0000)) // red mask
		data.write(UInt32(0x0000FF00)) // green mask
		data.write(UInt32(0x000000FF)) // blue mask
		data.write(UInt32(0xFF000000)) // alpha mask
		
		data.write("Win ", length: 4) // color space (default)
		
		data.jump(bytes: 36) // endpoints (unused)
		data.jump(bytes: 12) // response curves (unused)
		
		data.write(contents)
	}
}

extension BMP: ProprietaryFileData {
	static let fileExtension = ".bmp"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> Self { self }
	func unpacked(configuration: Configuration) -> Self { self }
}
