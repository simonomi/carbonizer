//
//  DMS.swift
//  
//
//  Created by alice on 2023-11-25.
//

import BinaryParser

struct DMS: Codable, Writeable {
	var value: UInt32
	
	@BinaryConvertible
	struct Binary: Writeable {
		var magicBytes = "DMS"
		var value: UInt32
	}
}

// MARK: packed
extension DMS: FileData {
	static var packedFileExtension = ""
	static var unpackedFileExtension = "dms.json"
	
	init(packed: Binary) {
		value = packed.value
	}
}

extension DMS.Binary: InitFrom {
	init(_ dms: DMS) {
		value = dms.value
	}
}

// MARK: unpacked
extension DMS {
	init(from decoder: Decoder) throws {
		value = try UInt32(from: decoder)
	}
	
	func encode(to encoder: Encoder) throws {
		try value.encode(to: encoder)
	}
}
