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
		data.seek(to: header.arm9Offset)
		arm9 = try data.read(header.arm9Size)
		data.seek(to: header.arm9OverlayOffset)
		arm9Overlay = try data.read(header.arm9OverlaySize)
		
		// arm7
		data.seek(to: header.arm7Offset)
		arm7 = try data.read(header.arm7Size)
		data.seek(to: header.arm7OverlayOffset)
		arm7Overlay = try data.read(header.arm7OverlaySize)
		
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
			length: header.fileAllocationTableSize
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
	
	init(from folder: Folder) throws {
		guard case .binaryFile(let headerFile) =		folder.getChild(named: "header.json"),
			  case .binaryFile(let arm9File) =			folder.getChild(named: "arm9.bin"),
			  case .binaryFile(let arm9OverlayFile) =	folder.getChild(named: "arm9 overlay.bin"),
			  case .binaryFile(let arm7File) =			folder.getChild(named: "arm7.bin"),
			  case .binaryFile(let arm7OverlayFile) =	folder.getChild(named: "arm7 overlay.bin"),
			  case .binaryFile(let iconBannerFile) =	folder.getChild(named: "icon banner.bin"),
			  case .folder(let dataFolder) =			folder.getChild(named: "data")
		else {
			fatalError()
		}
		
		name = folder.name + ".nds"
		header = try JSONDecoder().decode(Header.self, from: headerFile.contents)
		arm9 = arm9File.contents
		arm9Overlay = arm9OverlayFile.contents
		arm7 = arm7File.contents
		arm7Overlay = arm7OverlayFile.contents
		iconBanner = iconBannerFile.contents
		contents = dataFolder.children
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
	
	struct Header: Codable {
		var gameTitle: String
		var gamecode: String
		var makercode: String
		var unitcode: UInt8
		var encryptionSeedSelect: UInt8
		var deviceCapacity: UInt8
		var reserved1: Data
		var ndsRegion: UInt16
		var romVersion: UInt8
		var internalFlags: UInt8
		var arm9Offset: UInt32
		var arm9EntryAddress: UInt32
		var arm9LoadAddress: UInt32
		var arm9Size: UInt32
		var arm7Offset: UInt32
		var arm7EntryAddress: UInt32
		var arm7LoadAddress: UInt32
		var arm7Size: UInt32
		var fileNameTableOffset: UInt32
		var fileNameTableSize: UInt32
		var fileAllocationTableOffset: UInt32
		var fileAllocationTableSize: UInt32
		var arm9OverlayOffset: UInt32
		var arm9OverlaySize: UInt32
		var arm7OverlayOffset: UInt32
		var arm7OverlaySize: UInt32
		var normalCardControlRegisterSettings: UInt32
		var secureCardControlRegisterSettings: UInt32
		var iconBannerOffset: UInt32
		var secureAreaCRC: UInt16
		var secureTransferTimeout: UInt16
		var arm9Autoload: UInt32
		var arm7Autoload: UInt32
		var secureDisable: UInt64
		var totalROMSize: UInt32
		var headerSize: UInt32
		var reserved2: Data
		var nintendoLogo: Data
		var nintendoLogoCRC: UInt16
		var headerCRC: UInt16
		var debuggerReserved: Data
		
		init(from data: Datastream) throws {
			gameTitle =							try data.readString(length: 12)
			gamecode =							try data.readString(length: 4)
			makercode =							try data.readString(length: 2)
			unitcode =							try data.read(UInt8.self)
			encryptionSeedSelect =				try data.read(UInt8.self)
			deviceCapacity =					try data.read(UInt8.self)
			reserved1 =							try data.read(7)
			ndsRegion =							try data.read(UInt16.self)
			romVersion =						try data.read(UInt8.self)
			internalFlags =						try data.read(UInt8.self)
			arm9Offset =						try data.read(UInt32.self)
			arm9EntryAddress =					try data.read(UInt32.self)
			arm9LoadAddress =					try data.read(UInt32.self)
			arm9Size =							try data.read(UInt32.self)
			arm7Offset =						try data.read(UInt32.self)
			arm7EntryAddress =					try data.read(UInt32.self)
			arm7LoadAddress =					try data.read(UInt32.self)
			arm7Size =							try data.read(UInt32.self)
			fileNameTableOffset =				try data.read(UInt32.self)
			fileNameTableSize =					try data.read(UInt32.self)
			fileAllocationTableOffset =			try data.read(UInt32.self)
			fileAllocationTableSize =			try data.read(UInt32.self)
			arm9OverlayOffset =					try data.read(UInt32.self)
			arm9OverlaySize =					try data.read(UInt32.self)
			arm7OverlayOffset =					try data.read(UInt32.self)
			arm7OverlaySize =					try data.read(UInt32.self)
			normalCardControlRegisterSettings =	try data.read(UInt32.self)
			secureCardControlRegisterSettings =	try data.read(UInt32.self)
			iconBannerOffset =					try data.read(UInt32.self)
			secureAreaCRC =						try data.read(UInt16.self)
			secureTransferTimeout =				try data.read(UInt16.self)
			arm9Autoload =						try data.read(UInt32.self)
			arm7Autoload =						try data.read(UInt32.self)
			secureDisable =						try data.read(UInt64.self)
			totalROMSize =						try data.read(UInt32.self)
			headerSize =						try data.read(UInt32.self)
			reserved2 =							try data.read(56)
			nintendoLogo =						try data.read(156)
			nintendoLogoCRC =					try data.read(UInt16.self)
			headerCRC =							try data.read(UInt16.self)
			debuggerReserved =					try data.read(32)
		}
		
		func write(to data: Datawriter) throws {
			try data.write(gameTitle)
			try data.write(gamecode)
			try data.write(makercode)
			data.write(unitcode)
			data.write(encryptionSeedSelect)
			data.write(deviceCapacity)
			data.write(reserved1)
			data.write(ndsRegion)
			data.write(romVersion)
			data.write(internalFlags)
			data.write(arm9Offset)
			data.write(arm9EntryAddress)
			data.write(arm9LoadAddress)
			data.write(arm9Size)
			data.write(arm7Offset)
			data.write(arm7EntryAddress)
			data.write(arm7LoadAddress)
			data.write(arm7Size)
			data.write(fileNameTableOffset)
			data.write(fileNameTableSize)
			data.write(fileAllocationTableOffset)
			data.write(fileAllocationTableSize)
			data.write(arm9OverlayOffset)
			data.write(arm9OverlaySize)
			data.write(arm7OverlayOffset)
			data.write(arm7OverlaySize)
			data.write(normalCardControlRegisterSettings)
			data.write(secureCardControlRegisterSettings)
			data.write(iconBannerOffset)
			data.write(secureAreaCRC)
			data.write(secureTransferTimeout)
			data.write(arm9Autoload)
			data.write(arm7Autoload)
			data.write(secureDisable)
			data.write(totalROMSize)
			data.write(headerSize)
			data.write(reserved2)
			data.write(nintendoLogo)
			data.write(nintendoLogoCRC)
			data.write(headerCRC)
			data.write(debuggerReserved)
		}
		
		enum CodingKeys: String, CodingKey {
			case gameTitle = "Game Title"
			case gamecode = "Gamecode"
			case makercode = "Makercode"
			case unitcode = "Unitcode"
			case encryptionSeedSelect = "Encryption seed select"
			case deviceCapacity = "Devicecapacity"
			case reserved1 = "Reserved (1)"
			case ndsRegion = "NDS Region"
			case romVersion = "ROM Version"
			case internalFlags = "Internal flags, (Bit2: Autostart)"
			case arm9Offset = "ARM9 offset"
			case arm9EntryAddress = "ARM9 entry address"
			case arm9LoadAddress = "ARM9 load address"
			case arm9Size = "ARM9 size"
			case arm7Offset = "ARM7 offset"
			case arm7EntryAddress = "ARM7 entry address"
			case arm7LoadAddress = "ARM7 load address"
			case arm7Size = "ARM7 size"
			case fileNameTableOffset = "File Name Table (FNT) offset"
			case fileNameTableSize = "File Name Table (FNT) size"
			case fileAllocationTableOffset = "File Allocation Table (FAT) offset"
			case fileAllocationTableSize = "File Allocation Table (FAT) size"
			case arm9OverlayOffset = "ARM9 overlay offset"
			case arm9OverlaySize = "ARM9 overlay size"
			case arm7OverlayOffset = "ARM7 overlay offset"
			case arm7OverlaySize = "ARM7 overlay size"
			case normalCardControlRegisterSettings = "Normal card control register settings"
			case secureCardControlRegisterSettings = "Secure card control register settings"
			case iconBannerOffset = "Icon Banner offset"
			case secureAreaCRC = "Secure area (2K) CRC"
			case secureTransferTimeout = "Secure transfer timeout"
			case arm9Autoload = "ARM9 autoload"
			case arm7Autoload = "ARM7 autoload"
			case secureDisable = "Secure disable"
			case totalROMSize = "Total ROM size"
			case headerSize = "Header size"
			case reserved2 = "Reserved (2)"
			case nintendoLogo = "Nintendo Logo"
			case nintendoLogoCRC = "Nintendo Logo CRC"
			case headerCRC = "Header CRC"
			case debuggerReserved = "Debugger reserved"
		}
	}
	
	struct FileNameTable {
		var mainTable: [MainEntry]
		var subTable: [[SubEntry]]
		
		init() {
			mainTable = []
			subTable = []
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
		
		func write(to data: Datawriter) throws {
			mainTable.forEach { $0.write(to: data) }
			for table in subTable {
				try table.forEach { try $0.write(to: data) }
				data.write(UInt8.zero)
			}
		}
		
		var size: Int {
			mainTable.count * 8 + subTable.flatMap { $0.map(\.byteLength) + [1] }.sum()
		}
		
		var zippedTables: [(main: MainEntry, sub: [SubEntry])] {
			Array(zip(mainTable, subTable))
		}
		
		struct MainEntry {
			var id: UInt16
			var subTableOffset: UInt32
			var firstChildId: UInt16
			var parentId: UInt16 // for first entry, number of folders instead of parent id
			
			init(id: UInt16, subTableOffset: UInt32, firstChildId: UInt16, parentId: UInt16) {
				self.id = id
				self.subTableOffset = subTableOffset
				self.firstChildId = firstChildId
				self.parentId = parentId
			}
			
			init(from data: Datastream, id: UInt16) throws {
				self.id = id

				subTableOffset = try data.read(UInt32.self)
				firstChildId =   try data.read(UInt16.self)
				parentId =       try data.read(UInt16.self)
			}
			
			func write(to data: Datawriter) {
				data.write(subTableOffset)
				data.write(firstChildId)
				data.write(parentId)
			}
		}
		
		struct SubEntry {
			var type: EntryType
			var name: String
			var id: UInt16
			
			enum EntryType {
				case file, folder
			}
			
			init(type: EntryType, name: String, id: UInt16) {
				self.type = type
				self.name = name
				self.id = id
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
			
			func write(to data: Datawriter) throws {
				let nameLength: UInt8
				switch type {
					case .file:
						nameLength = UInt8(name.count)
					case .folder:
						nameLength = UInt8(name.count + 0x80)
				}
				
				data.write(nameLength)
				try data.write(name)
				
				if type == .folder {
					data.write(id)
				}
			}
			
			var byteLength: Int {
				switch type {
					case .file:
						return name.count + 1
					case .folder:
						return name.count + 3
				}
			}
		}
	}
	
	struct FileAllocationTable {
		var entries: [Entry]
		
		init() {
			entries = []
		}
		
		init(from data: Datastream, offset: UInt32, length: UInt32) throws {
			data.seek(to: offset)
			let entryCount = length / 8
			entries = try (0..<entryCount).map { _ in
				try Entry(from: data)
			}
		}
		
		func write(to data: Datawriter) {
			for entry in entries {
				entry.write(to: data)
			}
		}
		
		struct Entry {
			var startAddress: UInt32
			var endAddress: UInt32
			
			init(startAddress: UInt32, endAddress: UInt32) {
				self.startAddress = startAddress
				self.endAddress = endAddress
			}
			
			init(from data: Datastream) throws {
				startAddress =	try data.read(UInt32.self)
				endAddress =	try data.read(UInt32.self)
			}
			
			func write(to data: Datawriter) {
				data.write(startAddress)
				data.write(endAddress)
			}
			
			var length: Int {
				Int(endAddress - startAddress)
			}
		}
	}
}

extension Folder {
	init(from ndsFile: NDSFile) throws {
		name = ndsFile.name.replacing(#/\.nds$/#, with: "")
		
		let headerData = try JSONEncoder(.prettyPrinted).encode(ndsFile.header)
		
		children = [
			.binaryFile(BinaryFile(name: "header.json", contents: headerData)),
			.binaryFile(BinaryFile(name: "arm9.bin", contents: ndsFile.arm9)),
			.binaryFile(BinaryFile(name: "arm9 overlay.bin", contents: ndsFile.arm9Overlay)),
			.binaryFile(BinaryFile(name: "arm7.bin", contents: ndsFile.arm7)),
			.binaryFile(BinaryFile(name: "arm7 overlay.bin", contents: ndsFile.arm7Overlay)),
			.binaryFile(BinaryFile(name: "icon banner.bin", contents: ndsFile.iconBanner)),
			.folder(Folder(name: "data", children: ndsFile.contents))
		]
	}
}

extension BinaryFile {
	init(from ndsFile: NDSFile) throws {
		name = ndsFile.name
		
		var header = ndsFile.header
		let data = Datawriter()
		
		// arm9
		data.seek(to: 0x4000)
		header.arm9Offset = UInt32(data.offset)
		header.arm9Size = UInt32(ndsFile.arm9.count)
		data.write(ndsFile.arm9)
		
		// arm9 overlay
		data.fourByteAlign()
		header.arm9OverlayOffset = UInt32(data.offset)
		header.arm9OverlaySize = UInt32(ndsFile.arm9Overlay.count)
		data.write(ndsFile.arm9Overlay)
		
		// arm7
		data.fourByteAlign()
		header.arm7Offset = UInt32(data.offset)
		header.arm7Size = UInt32(ndsFile.arm7.count)
		data.write(ndsFile.arm7)
		
		// arm7 overlay
		data.fourByteAlign()
		header.arm7OverlayOffset = UInt32(data.offset)
		header.arm7OverlaySize = UInt32(ndsFile.arm7Overlay.count)
		data.write(ndsFile.arm7Overlay)
		
		// icon banner
		data.fourByteAlign()
		header.iconBannerOffset = UInt32(data.offset)
		data.write(ndsFile.iconBanner)
		
		// create file name table TODO: move this into a function on filenametable
		let rootFolder = Folder(name: "", children: ndsFile.contents)
		let folderTree = rootFolder.getFolderTree()
		let folderIds = folderTree.indices.map { $0 + 0xF000 }.map(UInt16.init)
		let allFolders = Array(zip(folderTree, folderIds))
		
		let fntMainTableSize = allFolders.count * 8
		
		var fileNameTable = NDSFile.FileNameTable()
		var fileId = UInt16.zero
		for (folder, folderId) in allFolders {
			let subTableOffset = fntMainTableSize + fileNameTable.subTable.flatMap { $0.map(\.byteLength) + [1] }.sum()
			
			let parentId: UInt16
			if fileNameTable.mainTable.isEmpty {
				parentId = UInt16(allFolders.count)
			} else {
				if let parentIndex = fileNameTable.subTable.firstIndex(where: { $0.contains { $0.id == folderId } }) {
					parentId = fileNameTable.mainTable[parentIndex].id
				} else {
					fatalError() // TODO: handle
				}
			}
			
			let mainEntry = NDSFile.FileNameTable.MainEntry(
				id: folderId,
				subTableOffset: UInt32(subTableOffset),
				firstChildId: fileId,
				parentId: parentId
			)
			
			var subTable = [NDSFile.FileNameTable.SubEntry]()
			for child in folder.children {
				let subEntry: NDSFile.FileNameTable.SubEntry
				switch child {
					case .folder(let folder):
						// note: not perfect, but i dont think this is ever validated so 🤷🏻‍♀️
						let subFolderId = allFolders.first {
							$0.0.name == folder.name && $0.0.children.count == folder.children.count
						}?.1 ?? UInt16.zero
						subEntry = NDSFile.FileNameTable.SubEntry(type: .folder, name: folder.name, id: subFolderId)
					case .binaryFile(let binaryFile):
						subEntry = NDSFile.FileNameTable.SubEntry(type: .file, name: binaryFile.name, id: fileId)
						fileId += 1
					default:
						continue
				}
				subTable.append(subEntry)
			}
			
			fileNameTable.mainTable.append(mainEntry)
			fileNameTable.subTable.append(subTable)
		}
		
		// write file name table
		data.fourByteAlign()
		header.fileNameTableOffset = UInt32(data.offset)
		header.fileNameTableSize = UInt32(fileNameTable.size)
		try fileNameTable.write(to: data)
		
		// create file allocation table
		let allFiles = rootFolder.getAllBinaryFiles()
		
		data.fourByteAlign()
		header.fileAllocationTableOffset = UInt32(data.offset)
		header.fileAllocationTableSize = UInt32(allFiles.count * 8)
		
		data.seek(bytes: header.fileAllocationTableSize)
		
		var fileAllocationTable = NDSFile.FileAllocationTable()
		
//		fileAllocationTable.entries +=
		
		
		
		for file in allFiles {
			data.fourByteAlign()
			
			let startAddress = data.offset
			data.write(file.contents)
			
			fileAllocationTable.entries.append(
				NDSFile.FileAllocationTable.Entry(
					startAddress: UInt32(startAddress),
					endAddress: UInt32(data.offset)
				)
			)
		}
		
		data.seek(to: header.fileAllocationTableOffset)
		fileAllocationTable.write(to: data)
		
		data.seek(to: 0)
		try header.write(to: data)
		
		contents = data.data
	}
}
