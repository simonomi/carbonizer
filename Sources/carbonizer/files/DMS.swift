//
//  DMS.swift
//  
//
//  Created by alice on 2023-11-25.
//

import BinaryParser

struct DMS: Codable {
	var value: UInt32
	
	@BinaryConvertible
	struct Binary {
		var magicBytes = "DMS"
		var value: UInt32
	}
}

// MARK: packed
extension DMS: FileData, InitFrom {
	init(packed: Binary) {
		value = packed.value
	}
}

extension DMS.Binary: InitFrom {
	init(_ dms: DMS) {
		value = dms.value
	}
}
