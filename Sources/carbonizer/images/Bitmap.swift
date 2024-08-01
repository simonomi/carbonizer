import BinaryParser
import Foundation

struct Bitmap {
	var width: Int32
	var height: Int32
	var contents: [RGB555Color?]
}

extension Bitmap: BinaryConvertible {
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
		data.write(-height)
		data.write(UInt16(1)) // planes
		data.write(UInt16(32)) // bits per pixel
		data.write(UInt32(3)) // compression (BITFIELDS)
		data.write(bitmapLength)
		data.write(UInt32(0x500)) // px/m (x)
		data.write(UInt32(0x500)) // px/m (y)
		data.write(UInt32.zero) // colors used (all)
		data.write(UInt32.zero) // colors important (all)
		data.write(UInt32(0x000000FF)) // red mask
		data.write(UInt32(0x0000FF00)) // green mask
		data.write(UInt32(0x00FF0000)) // blue mask
		data.write(UInt32(0xFF000000)) // alpha mask
		
		data.write("Win ", length: 4) // color space (default)
		
		data.jump(bytes: 36) // endpoints (unused)
		data.jump(bytes: 12) // response curves (unused)
		
		for pixel in contents {
			if let pixel {
				data.write(UInt8(pixel.red * 255))
				data.write(UInt8(pixel.green * 255))
				data.write(UInt8(pixel.blue * 255))
				data.write(UInt8(255)) // alpha
			} else {
				data.write(UInt32.zero) // transparent
			}
		}
	}
	
}

extension Bitmap: ProprietaryFileData {
    static let fileExtension = "bmp"
	static let packedStatus: PackedStatus = .unknown
	
	init(_ bitmap: Self) { self = bitmap }
}
