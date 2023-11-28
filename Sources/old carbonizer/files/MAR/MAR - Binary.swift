//
//  MAR <-> Binary.swift
//
//
//  Created by simon pellerin on 2023-06-18.
//

import Foundation

extension MARArchive {
	init(named name: String, from data: Data) throws {
		self.name = name
		
		let data = Datastream(data)
		
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
			contents.append(try MCMFile(index: index, data: fileData))
		}
	}
}

extension MARArchive.FileIndexTable {
	init(from data: Datastream, count: UInt32) throws {
		entries = try (0..<count).map { _ in
			try Entry(from: data)
		}
	}
	
	init(files: [Data]) {
		var currentOffset = 8 + (files.count * 8)
		entries = files.map { file in
			let oldOffset = currentOffset
			currentOffset += file.count
			
			currentOffset = currentOffset.toNearestMultiple(of: 4)
			
			// hacky :/
			let decompressedSize = UInt32(from: file[4..<8])!
			
			return Entry(
				offset: UInt32(oldOffset),
				decompressedSize: UInt32(decompressedSize)
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

extension Data {
	init(from marArchive: MARArchive) throws {
		let data = Datawriter()
		
		try data.write("MAR\0")
		
		data.write(UInt32(marArchive.contents.count))
		
		let compressedFiles = try marArchive.contents.map(Data.init)
		
		let fileIndexTable = MARArchive.FileIndexTable(files: compressedFiles)
		fileIndexTable.write(to: data)
		
		for file in compressedFiles {
			data.write(file)
			data.fourByteAlign()
		}
		
		self = data.data
	}
}
