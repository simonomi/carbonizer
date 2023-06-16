//
//  NDSFile.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

import Foundation

struct NDSFile: FileObject {
	var name: String
	var metadata: [Metadata]
	
	var contents: [File]
	
	init(named: String, from inputData: Data) throws {
		name = named
		
		let data = Datastream(inputData)
		
		let metadata = try NDSMetadata(from: data)
		self.metadata = [.ndsMetadata(metadata)]
		
		contents = try Self.createFolder(named: "", from: data, id: 0xF000, metadata: metadata).children
	}
	
	static func createFolder(
		named name: String,
		from data: Datastream,
		id: UInt16,
		metadata: NDSMetadata
	) throws -> Folder {
		let folderNumber = UInt32(id) - 0xF000
		data.seek(to: metadata.fileNameTableOffset + (folderNumber * 8))
		
		let mainEntry = try FNTMainEntry(from: data, id: id)
		data.seek(to: metadata.fileNameTableOffset + UInt32(mainEntry.subTableOffset))
		
		var children = [File]()
		var childId = mainEntry.firstChildId
		while let child = try FNTSubEntry(from: data, id: childId) {
			let offset = data.offset
			switch child.type {
				case .file:
					children.append(.binaryFile(try createFile(named: child.name, from: data, id: child.id, metadata: metadata)))
				case .folder:
					children.append(.folder(try createFolder(named: child.name, from: data, id: child.id, metadata: metadata)))
			}
			data.seek(to: offset)
			childId += 1
		}
		
		return Folder(name: name, children: children)
	}
	
	static func createFile(
		named name: String,
		from data: Datastream,
		id: UInt16,
		metadata: NDSMetadata
	) throws -> BinaryFile {
		data.seek(to: metadata.fileAllocationTableOffset)
		let startAddress = try data.read(UInt32.self)
		let endAddress = try data.read(UInt32.self)
		let length = endAddress - startAddress
		
		data.seek(to: startAddress)
		return BinaryFile(name: name, contents: try data.read(length))
	}
	
	struct FNTMainEntry {
		var id: UInt16
		var subTableOffset: UInt32
		var firstChildId: UInt16
		var parentId: UInt16 // note: for first entry, is number of folders instead
		
		init(from data: Datastream, id: UInt16) throws {
			self.id = id
			
			subTableOffset = try data.read(UInt32.self)
			firstChildId =   try data.read(UInt16.self)
			parentId =       try data.read(UInt16.self)
		}
	}
	
	struct FNTSubEntry {
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
}

struct NDSMetadata {
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
