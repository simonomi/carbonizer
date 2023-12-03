//
//  NDS.swift
//
//
//  Created by alice on 2023-11-25.
//

import BinaryParser
import Foundation

struct NDS {
	var header: Binary.Header
	
	var arm9: Datastream
	var arm9OverlayTable: [Binary.OverlayTableEntry]
	var arm9Overlays: [File]
	
	var arm7: Datastream
	var arm7OverlayTable: [Binary.OverlayTableEntry]
	var arm7Overlays: [File]
	
	var iconBanner: Datastream
	
	var contents: [any FileSystemObject]
	
	@BinaryConvertible
	struct Binary: Writeable {
		var header: Header
		
		@Offset(givenBy: \Self.header.arm9Offset)
		@Length(givenBy: \Self.header.arm9Size)
		var arm9: Datastream
		@Offset(givenBy: \Self.header.arm9OverlayOffset)
		@Count(givenBy: \Self.header.arm9OverlaySize, .dividedBy(32))
		var arm9OverlayTable: [OverlayTableEntry]
		
		@Offset(givenBy: \Self.header.arm7Offset)
		@Length(givenBy: \Self.header.arm7Size)
		var arm7: Datastream
		@Offset(givenBy: \Self.header.arm7OverlayOffset)
		@Count(givenBy: \Self.header.arm7OverlaySize, .dividedBy(32))
		var arm7OverlayTable: [OverlayTableEntry]
		
		@Offset(givenBy: \Self.header.iconBannerOffset)
		@Length(0x840)
		var iconBanner: Datastream
		
		@Offset(givenBy: \Self.header.fileNameTableOffset)
		var fileNameTable: FileNameTable
		
		@Offset(givenBy: \Self.header.fileAllocationTableOffset)
		@Count(givenBy: \Self.header.fileAllocationTableSize, .dividedBy(8))
		var fileAllocationTable: [FileAllocationTableEntry]
		
		@Offsets(givenBy: \Self.fileAllocationTable, from: \.startAddress, to: \.endAddress)
		var files: [Datastream]
		
		@BinaryConvertible
		struct Header: Codable {
			@Length(12)
			var gameTitle: String
			@Length(4)
			var gamecode: String
			@Length(2)
			var makercode: String
			var unitcode: UInt8
			var encryptionSeedSelect: UInt8
			var deviceCapacity: UInt8
			@Length(7)
			var reserved1: Datastream
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
			@Length(56)
			var reserved2: Datastream
			@Length(156)
			var nintendoLogo: Datastream
			var nintendoLogoCRC: UInt16
			var headerCRC: UInt16
			@Length(32)
			var reserved3: Datastream
		}
		
		@BinaryConvertible
		struct OverlayTableEntry: Codable {
			var id: UInt32
			var loadAddress: UInt32
			var ramSize: UInt32
			var bssSize: UInt32
			var staticInitializerStartAddress: UInt32
			var staticInitializerEndAddress: UInt32
			var fileId: UInt32
			var reserved: UInt32
		}
		
		@BinaryConvertible
		struct FileNameTable {
			var rootFolder: MainEntry
			@Count(givenBy: \Self.rootFolder.parentId, .minus(1))
			var mainTable: [MainEntry]
			@Offset(givenBy: \Self.rootFolder.subTableOffset)
			var rootSubTable: [SubEntry]
			@Offsets(givenBy: \Self.mainTable, at: \.subTableOffset)
			var subTables: [[SubEntry]]
			
			@BinaryConvertible
			struct MainEntry {
				var subTableOffset: UInt32
				var firstChildId: UInt16
				var parentId: UInt16 // for first entry, number of folders instead of parent id
			}
			
			@BinaryConvertible
			struct SubEntry {
				var typeAndNameLength: UInt8
				@Length(givenBy: \Self.typeAndNameLength, .modulo(0x80))
				var name: String
				@If(\Self.type, is: .equalTo(.folder))
				var id: UInt16?
			}
		}
		
		@BinaryConvertible
		struct FileAllocationTableEntry {
			var startAddress: UInt32
			var endAddress: UInt32
		}
	}
}

// MARK: packed
extension NDS: FileData {
	static var packedFileExtension = "nds"
	static var unpackedFileExtension = ""
	
	init(packed: Binary) throws {
		header = packed.header
		
		arm9 = packed.arm9
		arm9OverlayTable = packed.arm9OverlayTable
		arm9Overlays = try arm9OverlayTable.map {
			try File(
				named: "overlay \($0.fileId).bin",
				data: packed.files[Int($0.fileId)]
			)
		}
		
		arm7 = packed.arm7
		arm7OverlayTable = packed.arm7OverlayTable
		arm7Overlays = try arm7OverlayTable.map {
			try File(
				named: "overlay \($0.fileId).bin",
				data: packed.files[Int($0.fileId)]
			)
		}
		
		iconBanner = packed.iconBanner
		
		let completeTable = packed.fileNameTable.completeTable()
		contents = try completeTable[0xF000]!.map {
			try $0.createFileSystemObject(files: packed.files, fileNameTable: completeTable)
		}
	}
}

extension NDS.Binary: InitFrom {
	init(_ nds: NDS) {
		fatalError("TODO:")
	}
}

// MARK: unpacked
extension [any FileSystemObject] {
	fileprivate func getChild(named name: String) -> (any FileSystemObject)? {
		first { $0.name == name }
	}
}

extension NDS {
	enum UnpackingError: Error {
		case invalidFolderStructure([String])
	}
	
	init(unpacked: [any FileSystemObject]) throws {
		guard let headerFile =           unpacked.getChild(named: "header") as? File,
			  let headerData = headerFile.data as? Data,
			  
			  let arm9File =             unpacked.getChild(named: "arm9") as? File,
			  let arm9Data = arm9File.data as? Datastream,
			  
			  let arm9OverlayTableFile = unpacked.getChild(named: "arm9 overlay table") as? File,
			  let arm9OverlayTableData = arm9OverlayTableFile.data as? Data,
			  
			  let arm9OverlaysFolder =   unpacked.getChild(named: "arm9 overlays") as? Folder,
			  
			  let arm7File =             unpacked.getChild(named: "arm7") as? File,
			  let arm7Data = arm7File.data as? Datastream,
			  
			  let arm7OverlayTableFile = unpacked.getChild(named: "arm7 overlay table") as? File,
			  let arm7OverlayTableData = arm7OverlayTableFile.data as? Data,
			  
			  let arm7OverlaysFolder =   unpacked.getChild(named: "arm7 overlays") as? Folder,
			  
		      let iconBannerFile =       unpacked.getChild(named: "icon banner") as? File,
			  let iconBannerData = iconBannerFile.data as? Datastream,
			  
			  let dataFolder =           unpacked.getChild(named: "data") as? Folder else {
			throw UnpackingError.invalidFolderStructure(unpacked.map(\.name))
		}
		
		header = try JSONDecoder().decode(NDS.Binary.Header.self, from: headerData)
		
		arm9 = arm9Data
		arm9OverlayTable = try JSONDecoder().decode([NDS.Binary.OverlayTableEntry].self, from: arm9OverlayTableData)
		arm9Overlays = arm9OverlaysFolder.files.compactMap { $0 as? File }
		
		arm7 = arm7Data
		arm7OverlayTable = try JSONDecoder().decode([NDS.Binary.OverlayTableEntry].self, from: arm7OverlayTableData)
		arm7Overlays = arm7OverlaysFolder.files.compactMap { $0 as? File }
		
		iconBanner = iconBannerData
		
		contents = dataFolder.files
	}
	
	func toUnpacked() throws -> [any FileSystemObject] {
		let header = try JSONEncoder().encode(header)
		let arm9OverlayTable = try JSONEncoder().encode(arm9OverlayTable)
		let arm7OverlayTable = try JSONEncoder().encode(arm7OverlayTable)
		
		// TODO: give header and overlay tables .json extension
		return [
			File  (name: "header",             data:  header),
			File  (name: "arm9",               data:  arm9),
			File  (name: "arm9 overlay table", data:  arm9OverlayTable),
			Folder(name: "arm9 overlays",      files: arm9Overlays),
			File  (name: "arm7",               data:  arm7),
			File  (name: "arm7 overlay table", data:  arm7OverlayTable),
			Folder(name: "arm7 overlays",      files: arm7Overlays),
			File  (name: "icon banner",        data:  iconBanner),
			Folder(name: "data",               files: contents)
		]
	}
}
