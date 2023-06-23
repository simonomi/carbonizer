//
//  NDS <-> Binary.swift
//  
//
//  Created by simon pellerin on 2023-06-17.
//

import Foundation

extension NDSFile {
	init(named name: String, from inputData: Data) throws {
		self.name = name
		
		let data = Datastream(inputData)
		
		// header
		header = try Header(from: data)
		
		// arm9
		data.seek(to: header.arm9Offset)
		arm9 = try data.read(header.arm9Size)
		data.seek(to: header.arm9OverlayOffset)
		arm9OverlayTable = try OverlayTable(
			from: data,
			size: header.arm9OverlaySize
		)
		
		// arm7
		data.seek(to: header.arm7Offset)
		arm7 = try data.read(header.arm7Size)
		data.seek(to: header.arm7OverlayOffset)
		arm7OverlayTable = try OverlayTable(
			from: data,
			size: header.arm7OverlaySize
		)
		
		// icon banner
		data.seek(to: header.iconBannerOffset)
		iconBanner = try data.read(0x840) // hardcoded for version 1
		
		// file name table
		let fileNameTable = try FileNameTable(
			from: data,
			offset: header.fileNameTableOffset
		)
		
		// file allocation table
		data.seek(to: header.fileAllocationTableOffset)
		let fileAllocationTable = try FileAllocationTable(
			from: data,
			size: header.fileAllocationTableSize
		)
		
		// arm9 overlays
		arm9Overlays = try arm9OverlayTable.entries.map { overlay in
			let fileName = "overlay \(overlay.fileId).bin"
			return try Self.createFile(
				named: fileName,
				from: data,
				using: fileAllocationTable,
				id: UInt16(overlay.fileId)
			)
		}.sorted(by: \.name)
		
		// arm7 overlays
		arm7Overlays = try arm7OverlayTable.entries.map { overlay in
			let fileName = "overlay \(overlay.fileId).bin"
			return try Self.createFile(
				named: fileName,
				from: data,
				using: fileAllocationTable,
				id: UInt16(overlay.fileId)
			)
		}.sorted(by: \.name)
		
		// contents
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
					return FSFile.file(try createFile(
						named: subEntry.name,
						from: data,
						using: fileAllocationTable,
						id: subEntry.id
					))
				case .folder:
					return FSFile.folder(try createFolder(
						named: subEntry.name,
						from: data,
						using: fileNameTable,
						and: fileAllocationTable,
						id: subEntry.id
					))
			}
		}
		
		return Folder(named: name, children: children)
	}
	
	fileprivate static func createFile(
		named name: String,
		from data: Datastream,
		using fileAllocationTable: FileAllocationTable,
		id: UInt16
	) throws -> File {
		let fatEntry = fileAllocationTable.entries[Int(id)]
		
		data.seek(to: fatEntry.startAddress)
		let contents = try data.read(fatEntry.length)
		
		return try File(named: name, from: contents)
	}
}

extension NDSFile.Header {
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
}

extension NDSFile.FileNameTable {
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
	
	init(from folder: Folder, firstFileId: UInt16) throws {
		let folderTree = folder.getFolderTree()
		let folderIds = folderTree.indices.map { $0 + 0xF000 }.map(UInt16.init)
		let allFolders = Array(zip(folderTree, folderIds))
		
		let fntMainTableSize = allFolders.count * 8
		
		var fileId = firstFileId
		for (folder, folderId) in allFolders {
			let subTableOffset = fntMainTableSize + subTable.flatMap { $0.map(\.byteLength) + [1] }.sum()
			
			let parentId: UInt16
			if mainTable.isEmpty {
				parentId = UInt16(allFolders.count)
			} else {
				if let parentIndex = subTable.firstIndex(where: { $0.contains { $0.id == folderId } }) {
					parentId = mainTable[parentIndex].id
				} else {
					throw Datastream.ReadError.outOfBounds(
						index: Int(folderId),
						size: subTable.count,
						context: "FileNameTable.init"
					)
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
						// note: not perfect, but i dont think it's ever validated so 🤷🏻‍♀️
						let subFolderId = allFolders.first {
							$0.0.name == folder.name && $0.0.children.count == folder.children.count
						}?.1 ?? UInt16.zero
						subEntry = NDSFile.FileNameTable.SubEntry(type: .folder, name: folder.name, id: subFolderId)
					case .file(let file, _):
						subEntry = NDSFile.FileNameTable.SubEntry(type: .file, name: file.name, id: fileId)
						fileId += 1
				}
				subTable.append(subEntry)
			}
			
			mainTable.append(mainEntry)
			self.subTable.append(subTable)
		}
	}
	
	func write(to data: Datawriter) throws {
		mainTable.forEach { $0.write(to: data) }
		for table in subTable {
			try table.forEach { try $0.write(to: data) }
			data.write(UInt8.zero)
		}
	}
	
	var zippedTables: [(main: MainEntry, sub: [SubEntry])] {
		Array(zip(mainTable, subTable))
	}
	
	var size: Int {
		mainTable.count * 8 + subTable.flatMap { $0.map(\.byteLength) + [1] }.sum()
	}
}

extension NDSFile.FileNameTable.MainEntry {
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

extension NDSFile.FileNameTable.SubEntry {
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

extension NDSFile.FileAllocationTable {
	init(from data: Datastream, size: UInt32) throws {
		let entryCount = size / 8
		entries = try (0..<entryCount).map { _ in
			try Entry(from: data)
		}
	}
	
	func write(to data: Datawriter) {
		for entry in entries {
			entry.write(to: data)
		}
	}
}

extension NDSFile.FileAllocationTable.Entry {
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

extension NDSFile.OverlayTable {
	init(from data: Datastream, size: UInt32) throws {
		let entryCount = size / 32
		entries = try (0..<entryCount).map { _ in
			try Entry(from: data)
		}
	}
	
	func write(to data: Datawriter) {
		for entry in entries {
			entry.write(to: data)
		}
	}
	
	var size: Int {
		entries.count * 32
	}
}

extension NDSFile.OverlayTable.Entry {
	init(from data: Datastream) throws {
		id =							try data.read(UInt32.self)
		loadAddress =					try data.read(UInt32.self)
		size =							try data.read(UInt32.self)
		bssSize =						try data.read(UInt32.self)
		staticInitializerStartAddress =	try data.read(UInt32.self)
		staticInitializerEndAddress =	try data.read(UInt32.self)
		fileId =						try data.read(UInt32.self)
		reserved =						try data.read(UInt32.self)
	}
	
	func write(to data: Datawriter) {
		data.write(id)
		data.write(loadAddress)
		data.write(size)
		data.write(bssSize)
		data.write(staticInitializerStartAddress)
		data.write(staticInitializerEndAddress)
		data.write(fileId)
		data.write(reserved)
	}
}

extension Data {
	init(from ndsFile: NDSFile) throws {
		var header = ndsFile.header
		let data = Datawriter()
		
		// arm9
		data.seek(to: 0x4000)
		header.arm9Offset = UInt32(data.offset)
		header.arm9Size = UInt32(ndsFile.arm9.count)
		data.write(ndsFile.arm9)
		
		// arm9 overlay table
		if ndsFile.arm9Overlays.isEmpty {
			header.arm9OverlayOffset = 0
			header.arm9OverlaySize = 0
		} else {
			data.fourByteAlign()
			header.arm9OverlayOffset = UInt32(data.offset)
			header.arm9OverlaySize = UInt32(ndsFile.arm9OverlayTable.size)
			ndsFile.arm9OverlayTable.write(to: data)
		}
		
		// arm7
		data.fourByteAlign()
		header.arm7Offset = UInt32(data.offset)
		header.arm7Size = UInt32(ndsFile.arm7.count)
		data.write(ndsFile.arm7)
		
		// arm7 overlay table
		if ndsFile.arm7Overlays.isEmpty {
			header.arm7OverlayOffset = 0
			header.arm7OverlaySize = 0
		} else {
			data.fourByteAlign()
			header.arm7OverlayOffset = UInt32(data.offset)
			header.arm7OverlaySize = UInt32(ndsFile.arm7OverlayTable.size)
			ndsFile.arm7OverlayTable.write(to: data)
		}
		
		// icon banner
		data.fourByteAlign()
		header.iconBannerOffset = UInt32(data.offset)
		data.write(ndsFile.iconBanner)
		
		// create file name table
		let rootFolder = Folder(named: "", children: ndsFile.contents)
		let firstFileId = UInt16(ndsFile.arm9Overlays.count + ndsFile.arm7Overlays.count)
		let fileNameTable = try NDSFile.FileNameTable(from: rootFolder, firstFileId: firstFileId)
		
		// write file name table
		data.fourByteAlign()
		header.fileNameTableOffset = UInt32(data.offset)
		header.fileNameTableSize = UInt32(fileNameTable.size)
		try fileNameTable.write(to: data)
		
		// create file allocation table
		let allFiles = ndsFile.arm9Overlays + ndsFile.arm7Overlays + rootFolder.getAllFiles()
		
		data.fourByteAlign()
		header.fileAllocationTableOffset = UInt32(data.offset)
		header.fileAllocationTableSize = UInt32(allFiles.count * 8)
		
		data.seek(bytes: header.fileAllocationTableSize)
		
		var fileAllocationTable = NDSFile.FileAllocationTable()
		
		for file in allFiles {
			data.fourByteAlign()
			
			let startAddress = data.offset
			data.write(try Data(from: file))
			
			fileAllocationTable.entries.append(
				NDSFile.FileAllocationTable.Entry(
					startAddress: UInt32(startAddress),
					endAddress: UInt32(data.offset)
				)
			)
		}
		
		header.totalROMSize = UInt32(data.offset)
		
		data.seek(to: header.fileAllocationTableOffset)
		fileAllocationTable.write(to: data)
		
		data.seek(to: 0)
		try header.write(to: data)
		
		self = data.data
	}
}
