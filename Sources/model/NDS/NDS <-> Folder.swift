//
//  NDS <-> Folder.swift
//  
//
//  Created by simon pellerin on 2023-06-17.
//

import Foundation

extension NDSFile {
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
