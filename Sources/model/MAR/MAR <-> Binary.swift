//
//  MAR <-> Binary.swift
//
//
//  Created by simon pellerin on 2023-06-18.
//

extension MARArchive {
	init(from binaryFile: BinaryFile) throws {
		name = binaryFile.name
		
		let data = Datastream(binaryFile.contents)
		
		data.seek(bytes: 4)
		let numberOfFiles = try data.read(UInt32.self)
		
		let fileIndexTable = try FileIndexTable(from: data, count: numberOfFiles)
		
		let endOffsets = fileIndexTable.entries
			.map(\.offset)
			.dropFirst() + [UInt32(data.data.count)]
		
		contents = []
		for (index, (entry, endOffset)) in zip(fileIndexTable.entries, endOffsets).enumerated() {
			data.seek(to: entry.offset)
			let fileData = try data.read(to: endOffset)
			contents.append(.binaryFile(BinaryFile(name: String(index), contents: fileData)))
		}
	}
}

extension MARArchive.FileIndexTable {
	init(from data: Datastream, count: UInt32) throws {
		entries = try (0..<count).map { _ in
			try Entry(from: data)
		}
	}
}

extension MARArchive.FileIndexTable.Entry {
	init(from data: Datastream) throws {
		offset =			try data.read(UInt32.self)
		decompressedSize =	try data.read(UInt32.self)
	}
}

//extension BinaryFile {
//	init(from marArchive: MARArchive) throws {
//		
//	}
//}
