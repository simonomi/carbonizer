//
//  DTX.swift
//  
//
//  Created by alice on 2023-11-25.
//

import BinaryParser

struct DTX: Codable {
	var strings: [String]
	
	@BinaryConvertible
	struct Binary {
		var magicBytes = "DTX"
		var stringCount: UInt32
		var indexesOffset: UInt32 = 0xC
		@Offset(givenBy: \Self.indexesOffset)
		@Count(givenBy: \Self.stringCount)
		var indexes: [UInt32]
		@Offsets(givenBy: \Self.indexes)
		var strings: [String]
	}
}

// MARK: packed
extension DTX: FileData, InitFrom {
	init(packed: Binary) {
		strings = packed.strings
	}
}

extension DTX.Binary: InitFrom {
	init(_ dtx: DTX) {
		stringCount = UInt32(dtx.strings.count)

		indexes = createOffsets(
			start: indexesOffset + stringCount * 4,
			sizes: dtx.strings
				.map(\.utf8CString.count)
				.map(UInt32.init)
		)
		
		strings = dtx.strings
	}
}
