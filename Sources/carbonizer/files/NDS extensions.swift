//
//  NDS[SubEntry].swift
//
//
//  Created by alice on 2023-11-25.
//

import BinaryParser

extension [NDS.Binary.FileNameTable.SubEntry]: BinaryConvertible {
	public init(_ data: Datastream) throws {
		self = []
		while last?.typeAndNameLength != 0 {
			append(try data.read(NDS.Binary.FileNameTable.SubEntry.self))
		}
		removeLast()
	}
}

