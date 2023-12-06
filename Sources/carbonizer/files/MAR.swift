//
//  MAR.swift
//
//
//  Created by alice on 2023-11-25.
//

import BinaryParser
import Foundation

struct MAR {
	var files: [MCM]
	
	@BinaryConvertible
	struct Binary: Writeable {
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
	static var packedFileExtension = ""
	static var unpackedFileExtension = "mar"
	
	init(packed: Binary) throws {
		files = try packed.files.map(MCM.init)
	}
}

extension MAR.Binary: InitFrom {
	init(_ mar: MAR) {
		fileCount = UInt32(mar.files.count)
		
		files = mar.files.map(MCM.Binary.init)
		
		let firstFileIndex = 8 + fileCount * 8
		let mcmSizes = files.map(\.endOfFileOffset)
		let offsets = createOffsets(start: firstFileIndex, sizes: mcmSizes)
		
		let decompressedSizes = files.map(\.decompressedSize)
		
		indexes = zip(offsets, decompressedSizes).map(Index.init)
	}
}

// MARK: unpacked
extension MAR {
	init(unpacked: [any FileSystemObject]) throws {
		files = try unpacked.compactMap(as: File.self).map(MCM.init)
	}
	
	func toUnpacked() -> [any FileSystemObject] {
		files.enumerated().map(File.init)
	}
}
