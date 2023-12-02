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
	
	public func write(to data: BinaryParser.Datawriter) {
		forEach(data.write)
	}
}

extension Datawriter {
	func write(_ data: [NDS.Binary.FileNameTable.SubEntry]) {
		data.write(to: self)
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

extension NDS.Binary.Header {
	enum CodingKeys: String, CodingKey {
		case gameTitle = "Game Title"
		case gamecode = "Gamecode"
		case makercode = "Makercode"
		case unitcode = "Unitcode"
		case encryptionSeedSelect = "Encryption seed select"
		case deviceCapacity = "Device capacity"
		case reserved1 = "Reserved (1)"
		case ndsRegion = "NDS Region"
		case romVersion = "ROM Version"
		case internalFlags = "Internal flags"
		case arm9Offset = "ARM9 offset"
		case arm9EntryAddress = "ARM9 entry address"
		case arm9LoadAddress = "ARM9 load address"
		case arm9Size = "ARM9 size"
		case arm7Offset = "ARM7 offset"
		case arm7EntryAddress = "ARM7 entry address"
		case arm7LoadAddress = "ARM7 load address"
		case arm7Size = "ARM7 size"
		case fileNameTableOffset = "File Name Table offset"
		case fileNameTableSize = "File Name Table size"
		case fileAllocationTableOffset = "File Allocation Table offset"
		case fileAllocationTableSize = "File Allocation Table size"
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
		case reserved3 = "Reserved (3)"
	}
}

extension NDS.Binary.OverlayTableEntry {
	enum CodingKeys: String, CodingKey {
		case id =								"Overlay ID"
		case loadAddress =						"Load address"
		case ramSize =							"RAM size"
		case bssSize =							"BSS size"
		case staticInitializerStartAddress =	"Static initialiser start address"
		case staticInitializerEndAddress =		"Static initialiser end address"
		case fileId =							"File ID"
		case reserved =							"Reserved"
	}
}
