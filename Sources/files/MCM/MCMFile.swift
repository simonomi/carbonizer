//
//  MCMFile.swift
//
//
//  Created by simon pellerin on 2023-06-18.
//

import Foundation

struct MCMFile {
	var index: Int
	var compression: (CompressionType, CompressionType)
	var maxChunkSize: UInt32
	var content: File
	
	enum CompressionType: UInt8 {
		case none, runLengthEncoding, lzss, huffman
	}
}
