//
//  NDSFile.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

import Foundation

struct NDSFile {
	var name: String
	
	var header: Header
	
	var arm9: Data
	var arm9Overlay: Data
	
	var arm7: Data
	var arm7Overlay: Data
	
	var iconBanner: Data
	
	var contents = [File]()
	
	init(from binaryFile: BinaryFile) throws {
		name = binaryFile.name
		
		let data = Datastream(binaryFile.contents)
		
		// header
		header = try Header(from: data)
		
		// arm9
		data.seek(to: header.arm9RomOffset)
		arm9 = try data.read(header.arm9Size)
		data.seek(to: header.arm9OverlayOffset)
		arm9Overlay = try data.read(header.arm9OverlayLength)
		
		// arm7
		data.seek(to: header.arm7RomOffset)
		arm7 = try data.read(header.arm7Size)
		data.seek(to: header.arm7OverlayOffset)
		arm7Overlay = try data.read(header.arm7OverlayLength)
		
		// icon banner
		data.seek(to: header.iconBannerOffset)
		iconBanner = try data.read(0x840) // hardcoded for version 1
		
		// contents
		let fileNameTable = try FileNameTable(
			from: data,
			offset: header.fileNameTableOffset
		)
		
		let fileAllocationTable = try FileAllocationTable(
			from: data,
			offset: header.fileAllocationTableOffset,
			length: header.fileAllocationTableLength
		)
		
		let rootFolder = try Self.createFolder(
			named: "",
			from: data,
			using: fileNameTable,
			and: fileAllocationTable,
			id: 0xF000
		)
		contents = rootFolder.children
	}
	
	fileprivate static func createFolder(
		named name: String,
		from data: Datastream,
		using fileNameTable: FileNameTable,
		and fileAllocationTable: FileAllocationTable,
		id: UInt16
	) throws -> Folder {
		guard let (_, subTable) = fileNameTable.zippedTables.first(where: { $0.main.id == id }) else {
			throw Datastream.ReadError.outOfBounds(
				index: Int(id),
				size: fileNameTable.zippedTables.count,
				context: "createFolder"
			)
		}
		
		let children = try subTable.map { subEntry in
			switch subEntry.type {
				case .file:
					return File.binaryFile(try createFile(
						named: subEntry.name,
						from: data,
						using: fileAllocationTable,
						id: subEntry.id
					))
				case .folder:
					return File.folder(try createFolder(
						named: subEntry.name,
						from: data,
						using: fileNameTable,
						and: fileAllocationTable,
						id: subEntry.id
					))
			}
		}
		
		return Folder(name: name, children: children)
	}
	
	fileprivate static func createFile(
		named name: String,
		from data: Datastream,
		using fileAllocationTable: FileAllocationTable,
		id: UInt16
	) throws -> BinaryFile {
		let fatEntry = fileAllocationTable.entries[Int(id)]
		
		data.seek(to: fatEntry.startAddress)
		let contents = try data.read(fatEntry.length)
		
		return BinaryFile(name: name, contents: contents)
	}
	
	struct Header {
		let gameTitle: String
		let gamecode: String
		let makercode: String
		let unitcode: UInt8
		let encryptionSeedSelect: UInt8
		let deviceCapacity: UInt8
		let reserved1: Data
		let gameRevision: UInt16
		let romVersion: UInt8
		let internalFlags: UInt8
		let arm9RomOffset: UInt32
		let arm9EntryAddress: UInt32
		let arm9LoadAddress: UInt32
		let arm9Size: UInt32
		let arm7RomOffset: UInt32
		let arm7EntryAddress: UInt32
		let arm7LoadAddress: UInt32
		let arm7Size: UInt32
		let fileNameTableOffset: UInt32
		let fileNameTableLength: UInt32
		let fileAllocationTableOffset: UInt32
		let fileAllocationTableLength: UInt32
		let arm9OverlayOffset: UInt32
		let arm9OverlayLength: UInt32
		let arm7OverlayOffset: UInt32
		let arm7OverlayLength: UInt32
		let normalCardControlRegisterSettings: UInt32
		let secureCardControlRegisterSettings: UInt32
		let iconBannerOffset: UInt32
		let secureAreaCRC: UInt16
		let secureTransferTimeout: UInt16
		let arm9Autoload: UInt32
		let arm7Autoload: UInt32
		let secureDisable: UInt64
		let ntrRegionROMSize: UInt32
		let headerSize: UInt32
		let reserved2: Data
		let nintendoLogo: Data
		let nintendoLogoCRC: UInt16
		let headerCRC: UInt16
		let debuggerReserved: Data
		
		init(from data: Datastream) throws {
			gameTitle =							try data.readString(length: 12)
			gamecode =							try data.readString(length: 4)
			makercode =							try data.readString(length: 2)
			unitcode =							try data.read(UInt8.self)
			encryptionSeedSelect =				try data.read(UInt8.self)
			deviceCapacity =					try data.read(UInt8.self)
			reserved1 =							try data.read(7)
			gameRevision =						try data.read(UInt16.self)
			romVersion =						try data.read(UInt8.self)
			internalFlags =						try data.read(UInt8.self)
			arm9RomOffset =						try data.read(UInt32.self)
			arm9EntryAddress =					try data.read(UInt32.self)
			arm9LoadAddress =					try data.read(UInt32.self)
			arm9Size =							try data.read(UInt32.self)
			arm7RomOffset =						try data.read(UInt32.self)
			arm7EntryAddress =					try data.read(UInt32.self)
			arm7LoadAddress =					try data.read(UInt32.self)
			arm7Size =							try data.read(UInt32.self)
			fileNameTableOffset =				try data.read(UInt32.self)
			fileNameTableLength =				try data.read(UInt32.self)
			fileAllocationTableOffset =			try data.read(UInt32.self)
			fileAllocationTableLength =			try data.read(UInt32.self)
			arm9OverlayOffset =					try data.read(UInt32.self)
			arm9OverlayLength =					try data.read(UInt32.self)
			arm7OverlayOffset =					try data.read(UInt32.self)
			arm7OverlayLength =					try data.read(UInt32.self)
			normalCardControlRegisterSettings =	try data.read(UInt32.self)
			secureCardControlRegisterSettings =	try data.read(UInt32.self)
			iconBannerOffset =					try data.read(UInt32.self)
			secureAreaCRC =						try data.read(UInt16.self)
			secureTransferTimeout =				try data.read(UInt16.self)
			arm9Autoload =						try data.read(UInt32.self)
			arm7Autoload =						try data.read(UInt32.self)
			secureDisable =						try data.read(UInt64.self)
			ntrRegionROMSize =					try data.read(UInt32.self)
			headerSize =						try data.read(UInt32.self)
			reserved2 =							try data.read(56)
			nintendoLogo =						try data.read(156)
			nintendoLogoCRC =					try data.read(UInt16.self)
			headerCRC =							try data.read(UInt16.self)
			debuggerReserved =					try data.read(32)
		}
	}
	
	struct FileNameTable {
		var mainTable: [MainEntry]
		var subTable: [[SubEntry]]
		
		var zippedTables: [(main: MainEntry, sub: [SubEntry])] {
			Array(zip(mainTable, subTable))
		}
		
		struct MainEntry {
			var id: UInt16
			var subTableOffset: UInt32
			var firstChildId: UInt16
			var parentId: UInt16 // for first entry, number of folders instead of parent id
			
			init(from data: Datastream, id: UInt16) throws {
				self.id = id
				
				subTableOffset = try data.read(UInt32.self)
				firstChildId =   try data.read(UInt16.self)
				parentId =       try data.read(UInt16.self)
			}
		}
		
		struct SubEntry {
			var type: EntryType
			var name: String
			var id: UInt16
			
			enum EntryType {
				case file, folder
			}
			
			init?(from data: Datastream, id: UInt16) throws {
				let typeData = try data.read(UInt8.self)
				let nameLength: UInt8
				switch typeData {
					case 0x01...0x7F:
						type = .file
						nameLength = typeData
					case 0x81...0xFF:
						type = .folder
						nameLength = typeData - 0x80
					default:
						return nil
				}
				
				name = try data.readString(length: nameLength)
				
				switch type {
					case .file:
						self.id = id
					case .folder:
						self.id = try data.read(UInt16.self)
				}
			}
		}
		
		init(from data: Datastream, offset: UInt32) throws {
			data.seek(to: offset)
			let rootFolder = try MainEntry(from: data, id: 0xF000)
			let numberOfFolders = rootFolder.parentId
			
			mainTable = try [rootFolder] + (1..<numberOfFolders).map {
				try MainEntry(from: data, id: 0xF000 + $0)
			}
			
			subTable = try mainTable.map { mainEntry in
				var subEntries = [SubEntry]()
				var childId = mainEntry.firstChildId
				data.seek(to: offset + mainEntry.subTableOffset)
				while let child = try SubEntry(from: data, id: childId) {
					subEntries.append(child)
					childId += 1
				}
				return subEntries
			}
		}
	}
	
	struct FileAllocationTable {
		var entries: [Entry]
		
		init(from data: Datastream, offset: UInt32, length: UInt32) throws {
			data.seek(to: offset)
			let entryCount = length / 8
			entries = try (0..<entryCount).map { _ in
				try Entry(from: data)
			}
		}
		
		struct Entry {
			var startAddress: UInt32
			var endAddress: UInt32
			
			init(from data: Datastream) throws {
				self.startAddress =	try data.read(UInt32.self)
				self.endAddress =	try data.read(UInt32.self)
			}
			
			var length: Int {
				Int(endAddress - startAddress)
			}
		}
	}
}

//extension BinaryFile {
//	init(from ndsFile: NDSFile) {
//		
//	}
//}

//extension Folder {
//	init(from ndsFile: NDSFile) throws {
//
//	}
//}
