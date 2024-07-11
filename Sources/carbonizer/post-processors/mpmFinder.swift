import BinaryParser
import Foundation

func mpmFinder(_ file: consuming File, _ parent: Folder) throws -> [any FileSystemObject] {
	guard let mar = file.data as? MAR else { return [file] }
	
//	guard file.name == "all_map" else { return [file] }
	
	var images = [File]()
	
	for mpm in mar.files.compactMap({ $0.content as? MPM }) {
//		guard mpm.entry3 == nil else { continue }
//		print(file.name)
		
		let colorPaletteArchive = parent.files.first { $0.name == mpm.entry1.tableName } as! File
		let colorPaletteMAR = colorPaletteArchive.data as! MAR
		let colorPalette = colorPaletteMAR.files[Int(mpm.entry1.index)]
		let colorPaletteData = colorPalette.content as! Datastream
		colorPaletteData.offset = 0 // multiple files use the same palette
		let palette = try Palette(colorPaletteData)
		
//		print(palette.colors.count)
		
//		print(mpm.unknown1, mpm.unknown2, mpm.unknown3)
		
		// unknown4 has something to do with palette size
		// 1: 16, 2: 32, 4: 64, 8: 128, 16: 256
		// unknown4 * 16 == palette size
		
		let bitmapArchive = parent.files.first { $0.name == mpm.entry2.tableName } as! File
		let bitmapMAR = bitmapArchive.data as! MAR
		let bitmap = bitmapMAR.files[Int(mpm.entry2.index)]
		let bitmapData = bitmap.content as! Datastream
		
		let bitmapFile = Bitmap(
			width: Int32(mpm.width),
			height: Int32(mpm.height),
			contents: bitmapData.bytes.map {
				// color 0 is transparent, which is indicated by nil
				$0 == 0 ? nil : palette.colors[Int($0)]
			}
		)
		
		images.append(File(name: file.name, data: bitmapFile))
		
//		if let entry3 = mpm.entry3 {
//			let bgMapArchive = parent.files.first { $0.name == entry3.tableName } as! File
//			let bgMapMAR = bgMapArchive.data as! MAR
//			let bgMap = bgMapMAR.files[Int(entry3.index)]
//			let bgMapData = bgMap.content as! Datastream
//		}
	}
	
	return [file] + images
}
