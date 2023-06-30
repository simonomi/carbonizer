//
//  TextureFile.swift
//
//
//  Created by simon pellerin on 2023-06-25.
//

import Foundation

struct TextureFile {
	var name: String
	var bitmaps: [BitmapFile]
	
	func save(in path: URL, carbonized: Bool, with metadata: MCMFile.Metadata?) throws {
		// TODO: change if texture importing is added
		// ignores metadata because textures can't be imported (yet?)
		try Folder(from: self).save(in: path, carbonized: carbonized)
	}
	
	struct Palette {
		var name: String
		var bitmapOffset: UInt32
		var paletteOffset: UInt32
		var unknown1: UInt8
		var width: UInt16
		var height: UInt16
		var type: BitmapFile.TextureFormat
		var transparent: Bool
		var unknown3: UInt8
	}
}
