//
//  Texture - Folder.swift
//
//
//  Created by simon pellerin on 2023-06-27.
//

import Foundation

extension Folder {
	init(from textureFile: TextureFile) throws {
		name = textureFile.name + ".texture"
		children = try textureFile.bitmaps.map {
			.file(.binaryFile(BinaryFile(named: $0.name + ".bmp", contents: try Data(withoutTransparencyFrom: $0))))
		}
	}
}
