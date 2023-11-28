//
//  Data.swift
//
//
//  Created by simon pellerin on 2023-11-27.
//

import BinaryParser

extension Datastream: FileData, InitFrom {
	convenience init(packed: Datastream) {
		self.init(packed)
	}
	
	convenience init(unpacked: Datastream) {
		self.init(unpacked)
	}
	
	typealias InitsFrom = Datastream
}
