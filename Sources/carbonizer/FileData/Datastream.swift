//
//  Datastream.swift
//
//
//  Created by simon pellerin on 2023-11-27.
//

import BinaryParser

extension Datastream: FileData {
	convenience init(packed: Datastream) {
		self.init(packed)
	}
	
	convenience init(unpacked: Datastream) {
		self.init(unpacked)
	}
	
	func toPacked() -> Datastream { self }
	
	func toUnpacked() -> Datastream { self }
}
