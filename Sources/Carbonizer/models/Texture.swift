import BinaryParser

enum Texture {
	struct Packed {
		var imageCount: UInt32
		var bitmapsLength: UInt32
		var palettesLength: UInt32
		
		var imageHeaders: [ImageHeader]
		
		var bitmaps: [Datastream]
		
		var palettes: [Datastream]
		
		// bitmap size: width * height
		// palette size: ?
		@BinaryConvertible
		struct ImageHeader {
			@Length(16)
			var name: String
			
			var bitmapOffset: UInt32
			var paletteOffset: UInt32
			
			var unknown: UInt16 // redundant bitmap offset/8??
			
			var info: UInt16
		}
	}
	
	struct Unpacked: Codable {
		var images: [Image]
		
		struct Image: Codable {
			var name: String
			var unknown: UInt16
			var info: Info
			
			var bitmap: Datastream
			var palette: [Color]
			
			struct Info: Codable {
				var unknown1: UInt8 // 4 bits, always 0?
				var width: UInt32 // 3 bits (8 <<)
				var height: UInt32 // 3 bits (8 <<)
				var textureFormat: TextureFormat // 3 bits
				var transparent: Bool // 1 bit
				var unknown3: Bool // 1 bit
				var unknown4: Bool // 1 bit
				
				enum TextureFormat: String, Codable {
					case a3i5, twoBits, fourBits, eightBits, compressed, a5i3, direct
				}
			}
		}
	}
}

extension Texture.Packed: BinaryConvertible {
	init(_ data: Datastream) throws {
		imageCount = try data.read(UInt32.self)
		bitmapsLength = try data.read(UInt32.self)
		palettesLength = try data.read(UInt32.self)
		
		imageHeaders = try data.read([ImageHeader].self, count: imageCount)
		
		let bitmapOffsets = imageHeaders
			.map(\.bitmapOffset)
			.fixingZeroOffsets(endOffset: bitmapsLength)
		
		let bitmapsStart = data.placeMarker()
		bitmaps = try data.read(
			[Datastream].self,
			offsets: bitmapOffsets,
			endOffset: bitmapsLength,
			relativeTo: bitmapsStart // this is why this can't use macros
		)
		
		let paletteOffsets = imageHeaders
			.map(\.paletteOffset)
			.fixingZeroOffsets(endOffset: palettesLength)
		
		let palettesStart = data.placeMarker()
		palettes = try data.read(
			[Datastream].self,
			offsets: paletteOffsets,
			endOffset: palettesLength,
			relativeTo: palettesStart // this is why this can't use macros
		)
	}
	
	func write(to data: Datawriter) {
		data.write(imageCount)
		data.write(bitmapsLength)
		data.write(palettesLength)
		
		data.write(imageHeaders)
		
		let bitmapsStart = data.placeMarker()
		data.write(bitmaps, offsets: imageHeaders.map(\.bitmapOffset), relativeTo: bitmapsStart)
		
		let palettesStart = data.placeMarker()
		data.write(palettes, offsets: imageHeaders.map(\.paletteOffset), relativeTo: palettesStart)
	}
}

fileprivate extension [UInt32] {
	consuming func fixingZeroOffsets(endOffset: UInt32) -> Self {
		// if the first offset is 0, that's fine
		for index in indices.dropFirst() {
			if self[index] == 0 {
				// set this offset to the next offset, so the length is 0
				self[index] = self[safely: index + 1] ?? endOffset
			}
		}
		
		return self
	}
}

// MARK: packed
extension Texture.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) throws -> Texture.Unpacked {
		try Texture.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: Texture.Unpacked, configuration: Configuration) {
		todo()
		
		// this runs successfully, but doesnt output identical bytes
		
//		imageCount = UInt32(unpacked.images.count)
//		
//		var bitmapOffset: UInt32 = 0
//		var paletteOffset: UInt32 = 0
//		
//		imageHeaders = unpacked.images.map {
//			ImageHeader($0, bitmapOffset: &bitmapOffset, paletteOffset: &paletteOffset)
//		}
//		
//		bitmaps = unpacked.images.map(\.bitmap)
//		
//		palettes = unpacked.images
//			.map {
//				let writer = Datawriter()
//				for color in $0.palette {
//					writer.write(RGB555Color(color))
//				}
//				return writer.intoDatastream()
//			}
//		
//		
//		bitmapsLength = UInt32(bitmaps.map(\.bytes.count).sum())
//		
//		palettesLength = UInt32(palettes.map(\.bytes.count).sum())
	}
}

extension Texture.Packed.ImageHeader {
	fileprivate init(
		_ unpacked: Texture.Unpacked.Image,
		bitmapOffset: inout UInt32,
		paletteOffset: inout UInt32
	) {
		name = unpacked.name
		
		if unpacked.bitmap.bytes.count == 0 {
			self.bitmapOffset = 0
		} else {
			self.bitmapOffset = bitmapOffset
			bitmapOffset += UInt32(unpacked.bitmap.bytes.count)
		}
		
		if unpacked.palette.count == 0 {
			self.paletteOffset = 0
		} else {
			self.paletteOffset = paletteOffset
			paletteOffset += UInt32(unpacked.palette.count * 2)
		}
		
		unknown = unpacked.unknown
		
		info = unpacked.info.raw
	}
}

extension Texture.Unpacked.Image.Info {
	var raw: UInt16 {
		precondition(unknown1 < (1 << 4))
		
		let widthValue = UInt16((width / 8).trailingZeroBitCount)
		precondition(widthValue < (1 << 3))
		
		let heightValue = UInt16((height / 8).trailingZeroBitCount)
		precondition(heightValue < (1 << 3))
		
		return UInt16(unknown1) |
			(widthValue << 4) |
			(heightValue << 7) |
			(textureFormat.raw << 10) |
			((transparent ? 1 : 0) << 13) |
			((unknown3 ? 1 : 0) << 14) |
			((unknown4 ? 1 : 0) << 15)
	}
}

extension Texture.Unpacked.Image.Info.TextureFormat {
	var raw: UInt16 {
		switch self {
			case .a3i5: 1
			case .twoBits: 2
			case .fourBits: 3
			case .eightBits: 4
			case .compressed: 5
			case .a5i3: 6
			case .direct: 7
		}
	}
}

// MARK: unpacked
extension Texture.Unpacked: ProprietaryFileData {
	static let fileExtension = ".texture.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: Configuration) -> Texture.Packed {
		Texture.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: Texture.Packed, configuration: Configuration) throws {
		precondition(packed.imageHeaders.count == packed.bitmaps.count)
		precondition(packed.imageHeaders.count == packed.palettes.count)
		
		images = try zip(packed.imageHeaders, packed.bitmaps, packed.palettes)
			.map { (header, bitmap, palette) in
				try Image(header: header, bitmap: bitmap, palette: palette)
			}
	}
}

extension Texture.Unpacked.Image {
	fileprivate init(
		header: Texture.Packed.ImageHeader,
		bitmap bitmapData: Datastream,
		palette paletteData: Datastream
	) throws {
		name = header.name
		unknown = header.unknown
		info = try Info(raw: header.info)
		
		bitmap = bitmapData
		
		palette = try paletteData.read(
			[RGB555Color].self,
			count: paletteData.bytes.count / 2
		)
		.map(Color.init)
	}
}

extension Texture.Unpacked.Image.Info {
	init(raw: UInt16) throws {
		unknown1 = UInt8(raw & 0b1111)
		width = 8 << ((raw >> 4) & 0b111)
		height = 8 << ((raw >> 7) & 0b111)
		
		textureFormat = try TextureFormat(raw: UInt8((raw >> 10) & 0b111))
		
		transparent = (raw >> 13) & 0b1 > 0
		unknown3 = (raw >> 14) & 0b1 > 0
		unknown4 = (raw >> 15) & 0b1 > 0
	}
}

struct InvalidTextureFormat: Error {
	var raw: UInt8
	
	// TODO: CustomStringConvertible
}

extension Texture.Unpacked.Image.Info.TextureFormat {
	init(raw: UInt8) throws {
		self = switch raw {
			case 1: .a3i5
			case 2: .twoBits
			case 3: .fourBits
			case 4: .eightBits
			case 5: .compressed
			case 6: .a5i3
			case 7: .direct
			default: throw InvalidTextureFormat(raw: raw)
		}
	}
}

//extension TextureData {
//	func folder(named name: String) throws -> Folder {
//		Folder(
//			name: name,
//			metadata: .skipFile,
//			contents: try zip(imageHeaders, bitmaps, palettes).map(file)
//		)
//	}
//}

//fileprivate func file(
//	header: TextureData.ImageHeader,
//	bitmap: Datastream,
//	palette: [RGB555Color]
//) throws -> ProprietaryFile {
//	let headerInfo = try header.info()
//
//	var palette = palette.map { Bitmap.Color($0) }
//
//	if headerInfo.transparent {
//		palette[0] = .transparent
//	}
//
//	let pixelData = bitmap.bytes
//	let pixels: [Bitmap.Color]
//	switch headerInfo.type {
//		case .a3i5:
//			pixels = pixelData
//				.map {(
//					index: $0 & 0b11111,
//					alpha: $0 >> 5
//				)}
//				.map {
//					palette[Int($0.index)]
//						.replacingAlpha(with: Double($0.alpha) / 7)
//				}
//		case .twoBits:
//			pixels = pixelData
//				.flatMap { (byte: UInt8) -> [UInt8] in [
//					byte & 0b11,
//					byte >> 2 & 0b11,
//					byte >> 4 & 0b11,
//					byte >> 6
//				]}
//				.map { palette[Int($0)] }
//		case .fourBits:
//			pixels = pixelData
//				.flatMap {[
//					$0 & 0b1111,
//					$0 >> 4
//				]}
//				.map { palette[Int($0)] }
//		case .eightBits:
//			pixels = pixelData
//				.map { palette[Int($0)] }
//		case .compressed:
//			fatalError("i dont wanna do 4x4 compressed texture format")
//		case .a5i3:
//			pixels = pixelData
//				.map {(
//					index: $0 & 0b111,
//					alpha: $0 >> 3
//				)}
//				.map {
//					palette[Int($0.index)]
//						.replacingAlpha(with: Double($0.alpha) / 31)
//				}
//		case .direct:
//			pixels = pixelData
//				.chunked(exactSize: 2)
//				.map {
//					RGB555Color(
//						raw: $0
//							.enumerated()
//							.map { (index, byte) in
//								UInt16(byte) << (index * 8)
//							}
//							.reduce(0, |)
//					)
//				}
//				.map { Bitmap.Color($0) }
//	}
//
//	let bitmap = Bitmap(
//		width: headerInfo.width,
//		height: headerInfo.height,
//		contents: pixels
//	)
//
//	return ProprietaryFile(name: header.name, data: bitmap)
//}
