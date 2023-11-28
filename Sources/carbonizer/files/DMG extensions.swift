//
//  DMG.Binary.DMGString.swift
//
//
//  Created by simon pellerin on 2023-11-27.
//

extension DMG.Binary.DMGString {
	init(_ dmgString: DMG.DMGString) {
		index = dmgString.index
		string = dmgString.string
	}
}

extension DEX.Binary.Scene {
	init(_ commands: [DEX.MyCommand]) {
		fatalError()
	}
}
