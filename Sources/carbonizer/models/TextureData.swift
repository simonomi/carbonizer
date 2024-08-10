import BinaryParser

struct TextureData {
    var imageCount: UInt32
    var bitmapsLength: UInt32
    var palettesLength: UInt32
    
	@Count(givenBy: \Self.imageCount)
    var imageHeaders: [ImageHeader]
	
    var bitmaps: [Datastream]
    
	var palettes: [[RGB555Color]]
    
    @BinaryConvertible
    struct ImageHeader {
        @Length(16)
        var name: String
        
        var bitmapOffset: UInt32
        var paletteOffset: UInt32
        
        var unknown1: UInt16 // redundant bitmap offset/8??
        
        var rawInfo: UInt16
    }
}

struct ImageInfo {
	var unknown1: UInt8
	var width: Int32
	var height: Int32
	var type: TextureFormat
	var transparent: Bool
	var unknown3: Bool
	var unknown4: Bool
	
	enum TextureFormat: UInt8 {
		case a3i5 = 1, twoBits, fourBits, eightBits, compressed, a5i3, direct
	}
	
	struct InvalidTextureFormat: Error {
		var raw: UInt8
	}
	
	init(raw rawData: UInt16) throws {
		unknown1 = UInt8(rawData & 0b1111) // always 0?
		width = 8 << (rawData >> 4 & 0b111)
		height = 8 << (rawData >> 7 & 0b111)
		
		let textureFormatCode = UInt8(rawData >> 10 & 0b111)
		guard let textureFormat = TextureFormat(rawValue: textureFormatCode) else {
			throw InvalidTextureFormat(raw: textureFormatCode)
		}
		self.type = textureFormat
		
		transparent = (rawData >> 13 & 0b1) > 0
		unknown3 = (rawData >> 14 & 0b1) > 0
		unknown4 = (rawData >> 15 & 0b1) > 0
	}
}

extension TextureData.ImageHeader {
	func info() throws -> ImageInfo {
		try ImageInfo(raw: rawInfo)
	}
}

extension TextureData: BinaryConvertible {
	public init(_ data: Datastream) throws {
		imageCount = try data.read(UInt32.self)
		bitmapsLength = try data.read(UInt32.self)
		palettesLength = try data.read(UInt32.self)
		imageHeaders = try data.read([ImageHeader].self, count: imageCount)
		
		let bitmapsStart = data.placeMarker()
		bitmaps = try data.read(
			[Datastream].self,
			offsets: imageHeaders.map(\.bitmapOffset),
			endOffset: bitmapsLength,
			relativeTo: bitmapsStart
		)
		
		let palettesStart = data.placeMarker()
		palettes = try data.read(
			[Datastream].self,
            offsets: imageHeaders.map(\.paletteOffset),
			endOffset: palettesLength,
			relativeTo: palettesStart
		).map { paletteData in
			try (0..<paletteData.bytes.count / 2).map { _ in
				try paletteData.read(RGB555Color.self)
			}
		}
	}
	
	public func write(to data: Datawriter) {
		data.write(imageCount)
		data.write(bitmapsLength)
		data.write(palettesLength)
		data.write(imageHeaders)
		
		let bitmapsStart = data.placeMarker()
		data.write(bitmaps, offsets: imageHeaders.map(\.bitmapOffset), relativeTo: bitmapsStart)
		
		let palettesStart = data.placeMarker()
		for (header, palette) in zip(imageHeaders, palettes) {
			data.jump(to: palettesStart + header.paletteOffset)
			data.write(palette)
		}
	}
}

extension TextureData {
	func folder(named name: String) throws -> Folder {
		Folder(
			name: name,
			contents: try zip(imageHeaders, bitmaps, palettes).map(file)
		)
	}
}

fileprivate func file(
	header: TextureData.ImageHeader,
	bitmap: Datastream,
	palette: [RGB555Color]
) throws -> ProprietaryFile {
	let headerInfo = try header.info()
	
	var palette = palette.map { Bitmap.Color($0) }
	
	if headerInfo.transparent {
		palette[0] = .transparent
	}
	
	let pixelData = bitmap.bytes
	let pixels: [Bitmap.Color]
	switch headerInfo.type {
		case .a3i5:
			pixels = pixelData
				.map {(
					index: $0 & 0b11111,
					alpha: $0 >> 5
				)}
				.map {
					palette[Int($0.index)]
						.replacingAlpha(with: Double($0.alpha) / 7)
				}
		case .twoBits:
			pixels = pixelData
				.flatMap { (byte: UInt8) -> [UInt8] in [
					byte & 0b11,
					byte >> 2 & 0b11,
					byte >> 4 & 0b11,
					byte >> 6
				]}
				.map { palette[Int($0)] }
		case .fourBits:
			pixels = pixelData
				.flatMap {[
					$0 & 0b1111,
					$0 >> 4
				]}
				.map { palette[Int($0)] }
		case .eightBits:
			pixels = pixelData
				.map { palette[Int($0)] }
		case .compressed:
			fatalError("i dont wanna do 4x4 compressed texture format")
		case .a5i3:
			pixels = pixelData
				.map {(
					index: $0 & 0b111,
					alpha: $0 >> 3
				)}
				.map {
					palette[Int($0.index)]
						.replacingAlpha(with: Double($0.alpha) / 31)
				}
		case .direct:
			pixels = pixelData
				.chunked(exactSize: 2)
				.map {
					RGB555Color(
						raw: $0
							.enumerated()
							.map { (index, byte) in
								UInt16(byte) << (index * 8)
							}
							.reduce(0, |)
					)
				}
				.map { Bitmap.Color($0) }
	}
	
	let bitmap = Bitmap(
		width: headerInfo.width,
		height: headerInfo.height,
		contents: pixels
	)
	
	return ProprietaryFile(name: header.name, data: bitmap)
}
