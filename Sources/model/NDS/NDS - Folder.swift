//
//  NDS <-> Folder.swift
//  
//
//  Created by simon pellerin on 2023-06-17.
//

import Foundation

extension NDSFile {
	fileprivate enum DecodingError: Error {
		case folderNotFound(name: String)
	}
	
	init(from folder: Folder) throws {
		guard case .file(.binaryFile(let headerFile)) =				folder.getChild(named: "header.json"),
			  case .file(.binaryFile(let arm9File)) =				folder.getChild(named: "arm9.bin"),
			  case .file(.binaryFile(let arm9OverlayTableFile)) =	folder.getChild(named: "arm9 overlay table.bin"),
			  case .file(.binaryFile(let arm7File)) =				folder.getChild(named: "arm7.bin"),
			  case .file(.binaryFile(let arm7OverlayTableFile)) =	folder.getChild(named: "arm7 overlay table.bin"),
			  case .file(.binaryFile(let iconBannerFile)) =			folder.getChild(named: "icon banner.bin"),
			  case .folder(let dataFolder) =						folder.getChild(named: "data")
		else {
			throw DecodingError.folderNotFound(name: folder.children.map(\.name).joined(separator: ", "))
		}
		
		name = folder.name + ".nds"
		header = try JSONDecoder().decode(Header.self, from: headerFile.contents)
		
		arm9 = arm9File.contents
		arm9OverlayTable = try JSONDecoder().decode(OverlayTable.self, from: arm9OverlayTableFile.contents)
		if arm9OverlayTable.entries.isEmpty {
			arm9Overlays = []
		} else {
			guard case .folder(let arm9OverlaysFolder) = folder.getChild(named: "arm9 overlays") else {
				throw DecodingError.folderNotFound(name: "arm9 overlays")
			}
			arm9Overlays = arm9OverlaysFolder.getAllFiles()
		}
		
		arm7 = arm7File.contents
		arm7OverlayTable = try JSONDecoder().decode(OverlayTable.self, from: arm7OverlayTableFile.contents)
		if arm7OverlayTable.entries.isEmpty {
			arm7Overlays = []
		} else {
			guard case .folder(let arm7OverlaysFolder) = folder.getChild(named: "arm7 overlays") else {
				throw DecodingError.folderNotFound(name: "arm7 overlays")
			}
			arm7Overlays = arm7OverlaysFolder.getAllFiles()
		}
		
		iconBanner = iconBannerFile.contents
		contents = dataFolder.children
	}
}

extension NDSFile.Header {
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

extension NDSFile.OverlayTable {
	init(from decoder: Decoder) throws {
		entries = try [Entry](from: decoder)
	}
	
	func encode(to encoder: Encoder) throws {
		try entries.encode(to: encoder)
	}
}

extension NDSFile.OverlayTable.Entry {
	enum CodingKeys: String, CodingKey {
		case id =								"Overlay ID"
		case loadAddress =						"Load address"
		case size =								"RAM size"
		case bssSize =							"BSS size"
		case staticInitializerStartAddress =	"Static initialiser start address"
		case staticInitializerEndAddress =		"Static initialiser end address"
		case fileId =							"File ID"
		case reserved =							"Reserved"
	}
}

extension Folder {
	init(from ndsFile: NDSFile) throws {
		name = String(ndsFile.name.dropLast(4)) // remove .nds
		
		let headerData = try JSONEncoder(.prettyPrinted).encode(ndsFile.header)
		let arm9OverlayTableData = try JSONEncoder(.prettyPrinted).encode(ndsFile.arm9OverlayTable)
		let arm7OverlayTableData = try JSONEncoder(.prettyPrinted).encode(ndsFile.arm7OverlayTable)
		
		children = [
			.file(.binaryFile(BinaryFile(named: "header.json", contents: headerData))),
			.file(.binaryFile(BinaryFile(named: "arm9.bin", contents: ndsFile.arm9))),
			.file(.binaryFile(BinaryFile(named: "arm9 overlay table.bin", contents: arm9OverlayTableData))),
			.file(.binaryFile(BinaryFile(named: "arm7.bin", contents: ndsFile.arm7))),
			.file(.binaryFile(BinaryFile(named: "arm7 overlay table.bin", contents: arm7OverlayTableData))),
			.file(.binaryFile(BinaryFile(named: "icon banner.bin", contents: ndsFile.iconBanner))),
			.folder(Folder(named: "data", children: ndsFile.contents))
		]
		
		if !ndsFile.arm9Overlays.isEmpty {
			let arm9OverlayFiles = ndsFile.arm9Overlays.map { FSFile.file($0) }
			children.append(.folder(Folder(named: "arm9 overlays", children: arm9OverlayFiles)))
		}
		
		if !ndsFile.arm7Overlays.isEmpty {
			let arm7OverlayFiles = ndsFile.arm7Overlays.map { FSFile.file($0) }
			children.append(.folder(Folder(named: "arm7 overlays", children: arm7OverlayFiles)))
		}
	}
	
	func getChild(named name: String) -> FSFile? {
		children.first { $0.name == name }
	}
}
