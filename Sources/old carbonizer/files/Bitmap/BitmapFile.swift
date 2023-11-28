//
//  BitmapFile.swift
//
//
//  Created by simon pellerin on 2023-06-27.
//

import Foundation

struct BitmapFile {
	var name: String
	var width: Int32
	var height: Int32
	var contents: [Color]
	
	struct Color {
		var red: Double
		var green: Double
		var blue: Double
		var alpha: Double
	}
}
