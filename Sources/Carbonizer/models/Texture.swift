import Foundation
import BinaryParser

enum Texture {
	struct Packed {
		var imageCount: UInt32
		var bitmapsLength: UInt32
		var palettesLength: UInt32
		
		var imageHeaders: [ImageHeader]
		
		var bitmaps: [ByteSlice]
		
		var palettes: [ByteSlice]
		
		@BinaryConvertible
		struct ImageHeader {
			@Length(16)
			var name: String
			
			var bitmapOffset: UInt32
			var paletteOffset: UInt32
			
			var unknown: FixedPoint124 // seem to be monotonically increasing over each image in a texture
			
			var info: UInt16
		}
	}
	
	struct Unpacked: Codable {
		var images: [Image]
		
		struct Image: Codable {
			var name: String
			var unknown: Double
			var info: Info
			
			var paletteOffset: UInt32 // need this because it needs to match mesh's
			
			var bitmap: Data
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
	init(_ data: inout Datastream) throws {
		imageCount = try data.read(UInt32.self)
		bitmapsLength = try data.read(UInt32.self)
		palettesLength = try data.read(UInt32.self)
		
		imageHeaders = try data.read([ImageHeader].self, count: imageCount)
		
		let bitmapOffsets = imageHeaders
			.map(\.bitmapOffset)
			.fixingZeroOffsets(endOffset: bitmapsLength)
		
		let bitmapsStart = data.placeMarker()
		bitmaps = try data.read(
			[ByteSlice].self,
			offsets: bitmapOffsets,
			endOffset: bitmapsLength,
			relativeTo: bitmapsStart // this is why this can't use macros
		)
		
		let paletteOffsets = imageHeaders
			.map(\.paletteOffset)
			.fixingZeroOffsets(endOffset: palettesLength)
		
		let palettesStart = data.placeMarker()
		palettes = try data.read(
			[ByteSlice].self,
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
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) throws -> Texture.Unpacked {
		try Texture.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: Texture.Unpacked, configuration: Configuration) {
		imageCount = UInt32(unpacked.images.count)
		
		var bitmapOffset: UInt32 = 0

		imageHeaders = unpacked.images.map {
			ImageHeader($0, bitmapOffset: &bitmapOffset)
		}
		
		bitmaps = unpacked.images
			.map { Array($0.bitmap)[...] }
		
		palettes = unpacked.images
			.map {
				let writer = Datawriter()
				for color in $0.palette {
					writer.write(Color555(color))
				}
				return writer.bytes
			}
		
		bitmapsLength = UInt32(bitmaps.map(\.count).sum())
		
		palettesLength = UInt32(palettes.map(\.count).sum())
	}
}

extension Texture.Packed.ImageHeader {
	fileprivate init(
		_ unpacked: Texture.Unpacked.Image,
		bitmapOffset: inout UInt32
	) {
		name = unpacked.name
		
		if unpacked.bitmap.count == 0 {
			self.bitmapOffset = 0
		} else {
			self.bitmapOffset = bitmapOffset
			bitmapOffset += UInt32(unpacked.bitmap.count)
		}
		
		paletteOffset = unpacked.paletteOffset
		
		unknown = FixedPoint124(unpacked.unknown)
		
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
		bitmap bitmapData: ByteSlice,
		palette inputPaletteData: ByteSlice
	) throws {
		name = header.name
		unknown = Double(header.unknown)
		info = try Info(raw: header.info)
		
		paletteOffset = header.paletteOffset
		
		bitmap = Data(bitmapData)
		
		var paletteData = Datastream(inputPaletteData)
		palette = try paletteData.read(
			[Color555].self,
			count: inputPaletteData.count / 2
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

struct DuplicatePaletteOffsets: Error, CustomStringConvertible {
	var firstName: String
	var secondName: String
	
	var description: String {
		"duplicate palette offsets for \(.cyan)\(firstName)\(.normal) and \(.cyan)\(secondName)\(.normal)"
	}
}

struct DuplicateTextureNames: Error, CustomStringConvertible {
	var names: [String]
	
	var description: String {
		"texture names contain a duplicate: \(names)"
	}
}

extension Texture.Unpacked {
	func textureNames() throws -> [UInt32: String] {
		try Dictionary(
			images.map {
				// see http://problemkaputt.de/gbatek-ds-3d-texture-attributes.htm
				switch $0.info.textureFormat {
					case .twoBits:
						($0.paletteOffset >> 3, $0.name)
					default:
						($0.paletteOffset >> 4, $0.name)
				}
			}
		) {
			throw DuplicatePaletteOffsets(firstName: $0, secondName: $1)
		}
	}
	
	func texturesHaveTranslucency() throws -> [String: Bool] {
		try Dictionary(
			images.map { ($0.name, $0.info.transparent || $0.hasTranslucency()) }
		) { _, _ in
			throw DuplicateTextureNames(names: images.map(\.name))
		}
	}
	
	func folder(named name: String) throws -> Folder {
		Folder(
			name: name,
			metadata: .skipFile,
			contents: try images.map { try $0.file() }
		)
	}
}

extension Texture.Unpacked.Image {
	func hasTranslucency() -> Bool {
		switch info.textureFormat {
			case .a3i5, .a5i3:
				true // strictly speaking, we don't know for sure that the
					 // translucency is used, but it almost certainly is, right?
			case .twoBits, .fourBits, .eightBits, .direct:
				false
			case .compressed:
				todo("4x4 compressed texture format")
		}
	}
	
	fileprivate func file() throws -> ProprietaryFile {
		var palette = palette.map { BMP.Color($0) }
		
		if info.transparent {
			palette[0].alpha = 0
		}
		
		let pixelData = bitmap
		let pixels: [BMP.Color]
		switch info.textureFormat {
			case .a3i5:
				pixels = try pixelData
					.map {(
						index: $0 & 0b11111,
						alpha: $0 >> 5
					)}
					.map {
						try palette[safely: Int($0.index)]
							.orElseThrow(
								PaletteIndexOutOfBounds(
									index: Int($0.index),
									paletteCount: palette.count
								)
							)
							.replacingAlpha(with: Double($0.alpha) / Double((1 << 3) - 1))
					}
			case .twoBits:
				pixels = try pixelData
					.flatMap { (byte: UInt8) -> [UInt8] in [
						byte & 0b11,
						byte >> 2 & 0b11,
						byte >> 4 & 0b11,
						byte >> 6
					]}
					.map {
						try palette[safely: Int($0)]
							.orElseThrow(
								PaletteIndexOutOfBounds(
									index: Int($0),
									paletteCount: palette.count
								)
							)
					}
			case .fourBits:
				pixels = try pixelData
					.flatMap {[
						$0 & 0b1111,
						$0 >> 4
					]}
					.map {
						try palette[safely: Int($0)]
							.orElseThrow(
								PaletteIndexOutOfBounds(
									index: Int($0),
									paletteCount: palette.count
								)
							)
					}
			case .eightBits:
				pixels = try pixelData
					.map {
						try palette[safely: Int($0)]
							.orElseThrow(
								PaletteIndexOutOfBounds(
									index: Int($0),
									paletteCount: palette.count
								)
							)
					}
			case .compressed:
				fatalError("i dont wanna do 4x4 compressed texture format")
			case .a5i3:
				pixels = try pixelData
					.map {(
						index: $0 & 0b111,
						alpha: $0 >> 3
					)}
					.map {
						try palette[safely: Int($0.index)]
							.orElseThrow(
								PaletteIndexOutOfBounds(
									index: Int($0.index),
									paletteCount: palette.count
								)
							)
							.replacingAlpha(with: Double($0.alpha) / Double((1 << 5) - 1))
					}
			case .direct:
				pixels = pixelData
					.chunked(exactSize: 2)
					.map {
						Color555(
							raw: $0
								.enumerated()
								.map { (index, byte) in
									UInt16(byte) << (index * 8)
								}
								.reduce(0, |)
						)
					}
					.map { BMP.Color($0) }
		}
		
		let bitmap = BMP(
			width: info.width,
			height: info.height,
			contents: pixels
		)
		
		return ProprietaryFile(name: name, metadata: .skipFile, data: bitmap)
	}
}

struct PaletteIndexOutOfBounds: Error, CustomStringConvertible {
	var index: Int
	var paletteCount: Int
	
	var description: String {
		"palette \(.red)\(index)\(.normal) out of bounds, expected \(.green)\(0..<paletteCount)\(.normal)"
	}
}
