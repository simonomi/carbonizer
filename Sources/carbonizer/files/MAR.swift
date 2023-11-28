//
//  MAR.swift
//
//
//  Created by alice on 2023-11-25.
//

import BinaryParser

struct MAR {
	var files: [MCM]
	
	@BinaryConvertible
	struct Binary {
		var magicBytes = "MAR"
		var fileCount: UInt32
		@Count(givenBy: \Self.fileCount)
		var indexes: [Index]
		@Offsets(givenBy: \Self.indexes, at: \.fileOffset)
		var files: [MCM.Binary]
		
		@BinaryConvertible
		struct Index {
			var fileOffset: UInt32
			var decompressedSize: UInt32
		}
	}
}

// MARK: packed
extension MAR: FileData {
	init(packed: Binary) throws {
		files = try packed.files.map(MCM.init)
	}
}

extension MAR.Binary: InitFrom {
	init(_ mar: MAR) {
		fileCount = UInt32(mar.files.count)
		
		let firstFileIndex = 8 + fileCount * 8
		let compressedSizes = mar.files.map(\.compressedSize)
		let offsets = createOffsets(start: firstFileIndex, sizes: compressedSizes)
		
		let decompressedSizes = mar.files.map(\.decompressedSize)
		
		indexes = zip(offsets, decompressedSizes).map(Index.init)
		
		files = mar.files.map(MCM.Binary.init)
	}
}

// MARK: unpacked
extension MAR {
	init(unpacked: [File]) {
		files = unpacked.map(MCM.init)
	}
}

extension [File]: InitFrom {
	init(_ mar: MAR) {
		self = mar.files.enumerated().map(File.init)
	}
}
