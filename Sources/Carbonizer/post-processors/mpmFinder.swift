import BinaryParser
import Foundation

func mpmFinder(_ inputFile: consuming any FileSystemObject, _ parent: Folder) throws -> [any FileSystemObject] {
	let file: MAR.Unpacked
	switch inputFile {
		case let mar as MAR.Unpacked:
			file = mar
		case let other:
			return [other]
	}
	
//	guard file.name == "all_map" else { return [file] }
	
	var images = [ProprietaryFile]()
	
	for mpm in file.files.compactMap({ $0.content as? MPM.Unpacked }) {
//		guard mpm.entry3 == nil else { continue }
//		print(file.name)
//		print(mpm.entry3 == nil)
		
		let colorPaletteArchive = parent.contents.first { $0.name == mpm.palette.tableName } as! MAR.Unpacked
		let colorPalette = colorPaletteArchive.files[Int(mpm.palette.index)]
		let colorPaletteData = Datastream(colorPalette.content as! Datastream) // copy so as not to modify the original
		colorPaletteData.offset = 0 // multiple files use the same palette
		let palette = try Palette(colorPaletteData)
		
//		print(palette.colors.count)
		
//		print(mpm.unknown1, mpm.unknown2, mpm.unknown3)
		
		// unknown4 has something to do with palette size
		// 1: 16, 2: 32, 4: 64, 8: 128, 16: 256
		// unknown4 * 16 == palette size
		
		let bitmapArchive = parent.contents.first { $0.name == mpm.bitmap.tableName } as! MAR.Unpacked
		let bitmap = bitmapArchive.files[Int(mpm.bitmap.index)]
		let bitmapData = Datastream(bitmap.content as! Datastream) // copy so as not to modify the original
		
		let bitmapFile = Bitmap(
			width: Int32(mpm.width),
			height: Int32(mpm.height),
			contents: bitmapData.bytes.flatMap {
				// color 0 is transparent, which is indicated by nil
				if palette.colors.count == 16 {
					[
						($0 >> 4) == 0 ? .transparent : Bitmap.Color(palette.colors[Int($0 >> 4)]),
						($0 & 0b1111) == 0 ? .transparent : Bitmap.Color(palette.colors[Int($0 & 0b1111)])
					]
				} else {
					[$0 == 0 ? .transparent : Bitmap.Color(palette.colors[Int($0)])]
				}
			}
		)
		
		
		if mpm.bgMap != nil {
//		if let entry3 = mpm.entry3 {
//			let bgMapArchive = parent.contents.first { $0.name == entry3.tableName } as! MAR.Unpacked
//			let bgMap = bgMapArchive.files[Int(entry3.index)]
//			let bgMapData = Datastream(bgMap.content as! Datastream) // copy so as not to modify the original
			
			// TODO: images with bg maps
		} else {
			images.append(ProprietaryFile(name: file.name, metadata: .skipFile, data: bitmapFile))
		}
	}
	
	return [file] + images
}
