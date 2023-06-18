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
			contents.append(BinaryFile(name: String(index), contents: fileData))
		}
	}
}

extension MARArchive.FileIndexTable {
	init(from data: Datastream, count: UInt32) throws {
		entries = try (0..<count).map { _ in
			try Entry(from: data)
		}
	}
	
	init(files: [BinaryFile]) {
		var currentOffset = 8 + (files.count * 8)
		entries = files.map { file in
			let oldOffset = currentOffset
			currentOffset += file.contents.count
			
			if !currentOffset.isMultiple(of: 4) {
				currentOffset += 4 - (currentOffset % 4)
			}
			
			return Entry(
				offset: UInt32(oldOffset),
				decompressedSize: UInt32(file.contents.count)
			)
		}
	}
	
	func write(to data: Datawriter) {
		for entry in entries {
			entry.write(to: data)
		}
	}
}

extension MARArchive.FileIndexTable.Entry {
	init(from data: Datastream) throws {
		offset =			try data.read(UInt32.self)
		decompressedSize =	try data.read(UInt32.self)
	}
	
	func write(to data: Datawriter) {
		data.write(offset)
		data.write(decompressedSize)
	}
}

extension BinaryFile {
	init(from marArchive: MARArchive) throws {
		name = marArchive.name
		
		let data = Datawriter()
		
		try data.write("MAR\0")
		
		data.write(UInt32(marArchive.contents.count))
		
		let fileIndexTable = MARArchive.FileIndexTable(files: marArchive.contents)
		fileIndexTable.write(to: data)
		
		for file in marArchive.contents {
			data.write(file.contents)
			data.fourByteAlign()
		}
		
		contents = data.data
	}
}
