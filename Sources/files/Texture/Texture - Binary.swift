//
//  File.swift
//  
//
//  Created by simon pellerin on 2023-06-25.
//

import Foundation

extension TextureFile {
	init(named name: String, from inputData: Data) throws {
		self.name = name
		
		let data = Datastream(inputData)
		
		let paletteCount = try data.read(UInt32.self)
		let bitmapLength = try data.read(UInt32.self)
		let paletteLength = try data.read(UInt32.self)
		
		let paletteHeaders = try (0 ..< paletteCount).map { _ in
			try Palette(from: data)
		}
		
		let startBitmapOffsets = paletteHeaders.map(\.bitmapOffset)
		let endBitmapOffsets = startBitmapOffsets.dropFirst() + [bitmapLength]
		let bitmapLengths = zip(startBitmapOffsets, endBitmapOffsets).map { $1 - $0 }
		
		let bitmapData = try bitmapLengths.map {
			try data.read($0)
		}
		
		let startPaletteOffsets = paletteHeaders.map(\.paletteOffset)
		let endPaletteOffsets = startPaletteOffsets.dropFirst() + [paletteLength]
		var paletteLengths = zip(startPaletteOffsets, endPaletteOffsets).map {
			if $0 > $1 { return UInt32.zero }
			return $1 - $0
		}
		
		paletteHeaders
			.enumerated()
			.filter { $1.type == .direct }
			.map(\.offset)
			.forEach {
				paletteLengths.insert(0, at: $0)
				paletteLengths.removeLast()
			}
		
		let paletteData = try paletteLengths.map {
			try data.read($0)
		}
		
		bitmaps = try zip(paletteHeaders, paletteData, bitmapData)
			.map { header, palette, bitmap in
				try BitmapFile(
					name: header.name,
					width: Int32(header.width),
					height: Int32(header.height),
					type: header.type,
					palette: palette,
					pixels: bitmap
				)
			}
	}
}

extension TextureFile.Palette {
	enum ReadError: Error {
		case invalidTextureFormat(UInt8)
	}
	
	init(from data: Datastream) throws {
		let initialOffset = data.offset
		
		do {
			name = try data.readCString()
		} catch {
			// in model/fieldmap/arc/0369, one of the palette names is malformed
			// the first 4 characters are valid so, so just fall back to reading those
			name = try data.readString(length: 4)
		}
		data.seek(to: initialOffset + 16)
		
		bitmapOffset = try data.read(UInt32.self)
		paletteOffset = try data.read(UInt32.self)
		
		data.seek(bytes: 2) // redundant bitmap offset/8??
		
		let rawData = try data.read(UInt16.self)
		unknown1 = UInt8(rawData & 0b1111)
		width = 8 << (rawData >> 4 & 0b111)
		height = 8 << (rawData >> 7 & 0b111)
		
		let textureFormatCode = UInt8(rawData >> 10 & 0b111)
		guard let textureFormat = BitmapFile.TextureFormat(rawValue: textureFormatCode) else {
			throw ReadError.invalidTextureFormat(textureFormatCode)
		}
		self.type = textureFormat
		
		transparent = (rawData >> 13 & 0b1) > 0
		unknown3 = UInt8(rawData >> 14)
	}
}
