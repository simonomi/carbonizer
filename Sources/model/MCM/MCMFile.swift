//
//  MCMFile.swift
//
//
//  Created by simon pellerin on 2023-06-18.
//

import Foundation

struct MCMFile {
	var name: String
	var compression: (CompressionType, CompressionType)
	var maxChunkSize: UInt32
	var content: Data
	
	enum CompressionType {
		case none, runLengthEncoding, lzss, huffman
	}
}
