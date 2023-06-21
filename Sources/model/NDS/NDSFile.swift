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
	var arm9OverlayTable: OverlayTable
	var arm9Overlays: [File]
	
	var arm7: Data
	var arm7OverlayTable: OverlayTable
	var arm7Overlays: [File]
	
	var iconBanner: Data
	
	var contents = [FSFile]()
	
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
	}
	
	struct FileNameTable {
		var mainTable = [MainEntry]()
		var subTable = [[SubEntry]]()
		
		struct MainEntry {
			var id: UInt16
			var subTableOffset: UInt32
			var firstChildId: UInt16
			var parentId: UInt16 // for first entry, number of folders instead of parent id
		}
		
		struct SubEntry {
			var type: EntryType
			var name: String
			var id: UInt16
			
			enum EntryType {
				case file, folder
			}
		}
	}
	
	struct FileAllocationTable {
		var entries = [Entry]()
		
		struct Entry {
			var startAddress: UInt32
			var endAddress: UInt32
		}
	}
	
	struct OverlayTable: Codable {
		var entries = [Entry]()
		
		struct Entry: Codable {
			var id: UInt32
			var loadAddress: UInt32
			var size: UInt32
			var bssSize: UInt32
			var staticInitializerStartAddress: UInt32
			var staticInitializerEndAddress: UInt32
			var fileId: UInt32
			var reserved: UInt32
		}
	}
	
	func save(in path: URL, carbonized: Bool, with metadata: MCMFile.Metadata?) throws {
		if carbonized {
			let filePath = path.appendingPathComponent(name)
			try Data(from: self).write(to: filePath)
			if let metadata {
				try FileManager.setCreationDate(of: filePath, to: metadata.asDate())
			}
		} else {
			try Folder(from: self).save(in: path, carbonized: carbonized)
		}
	}
}
