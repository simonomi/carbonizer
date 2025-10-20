import BinaryParser

func imageExporterF(
	_ folder: inout Folder,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	let imageIndices = try environment.get(\.imageIndices)
	guard let tables = imageIndices[path] else { return }
	
	for file in folder.contents {
		guard let mar = file as? MAR.Unpacked,
			  let indices = tables[mar.name]
		else { continue }
		
		for imageIndices in indices {
			do {
				guard let palette = mar.files[imageIndices.paletteIndex].content as? Palette.Unpacked else {
					throw MissingImageComponent.palette(imageIndices.paletteIndex)
				}
				
				guard let bitmap = mar.files[imageIndices.bitmapIndex].content as? Datastream else {
					throw MissingImageComponent.bitmap(imageIndices.bitmapIndex)
				}
				
				if let bgMapIndex = imageIndices.bgMapIndex {
					throw MissingImageComponent.bgMap(bgMapIndex)
					
					// TODO: bg maps
				}
				
				let colors = palette.bmpColors()
				
				// 16-color bitmaps use 4-bit indices, everything else is 8-bit
				let bitmapIndices = if palette.colors.count == 16 {
					bitmap.bytes[bitmap.offset...].flatMap {
						[$0 >> 4, $0 & 0b1111]
					}
				} else {
					Array(bitmap.bytes[bitmap.offset...])
				}
				
				let bmp = BMP(
					width: imageIndices.width,
					height: imageIndices.height,
					contents: bitmapIndices
						.map { Int($0) }
						.map { colors[$0] }
				)
				
				let bmpFile = ProprietaryFile(
					name: imageIndices.imageName,
					metadata: .skipFile,
					data: bmp
				)
				
				folder.contents.append(bmpFile)
			} catch {
				let location = (path + [imageIndices.imageName]).joined(separator: "/") + ":"
				configuration.log(.warning, location, error)
			}
		}
	}
}

enum MissingImageComponent: Error, CustomStringConvertible {
	case palette(Int)
	case bitmap(Int)
	case bgMap(Int)
	
	var description: String {
		switch self {
			case .palette(let index):
				"missing palette \(index)"
			case .bitmap(let index):
				"missing bitmap \(index)"
			case .bgMap(let index):
				"missing bgMap \(index)"
		}
	}
}
