//
//  NDS extensions.swift
//
//
//  Created by alice on 2023-11-25.
//

import BinaryParser
import Foundation

extension [NDS.Binary.FileNameTable.SubEntry]: BinaryConvertible {
	public init(_ data: Datastream) throws {
		self = []
		while last?.typeAndNameLength != 0 {
			append(try data.read(NDS.Binary.FileNameTable.SubEntry.self))
		}
		removeLast()
	}
}

typealias CompleteFNT = [UInt16 : [NDS.Binary.FileNameTable.SubEntry]]

extension NDS.Binary.FileNameTable {
	func completeTable() -> CompleteFNT {
		let folderIds = (0..<rootFolder.parentId)
			.map { $0 + 0xF000 }
		let entries = zip([rootFolder] + mainTable, [rootSubTable] + subTables)
			.map { mainEntry, subEntries in
				zip(subEntries, mainEntry.firstChildId...)
					.map { subEntry, newId in
						if subEntry.type == .file {
							subEntry.givenId(newId)
						} else {
							subEntry
						}
					}
			}
		
		return Dictionary(uniqueKeysWithValues: zip(folderIds, entries))
	}
}

extension NDS.Binary.FileNameTable.SubEntry {
	enum FileOrFolder { case file, folder }
	var type: FileOrFolder {
		if self.typeAndNameLength < 0x80 {
			.file
		} else {
			.folder
		}
	}
	
	func givenId(_ id: UInt16) -> Self {
		Self(typeAndNameLength: typeAndNameLength, name: name, id: id)
	}
	
	func createFileSystemObject(files: [Datastream], fileNameTable: CompleteFNT) throws -> any FileSystemObject {
		switch type {
			case .file: 
				try File(named: name, data: files[Int(id!)])
			case .folder:
				Folder(
					name: name,
					files: try fileNameTable[id!]!
						.map { try $0.createFileSystemObject(files: files, fileNameTable: fileNameTable) }
				)
		}
	}
}
