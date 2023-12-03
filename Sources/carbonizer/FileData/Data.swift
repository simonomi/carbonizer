//
//  Data.swift
//  
//
//  Created by alice on 2023-12-01.
//

import BinaryParser
import Foundation

extension Data: FileData, Writeable {
	static var packedFileExtension = ""
	static var unpackedFileExtension = "bin"
	
	init(packed: Datastream) {
		self = Data(packed.bytes)
	}
}

extension Datastream: InitFrom {
	typealias InitsFrom = Data
}
