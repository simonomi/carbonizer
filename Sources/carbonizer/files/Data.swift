//
//  BinaryFile.swift
//
//
//  Created by simon pellerin on 2023-11-27.
//

import Foundation

extension Data: FileData, InitFrom {
	init(packed: Data) {
		self = packed
	}
	
	init(unpacked: Data) {
		self = unpacked
	}
	
	init(_ data: Data) {
		self = data
	}
}
