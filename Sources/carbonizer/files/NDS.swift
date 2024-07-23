import BinaryParser
import Foundation

struct NDS {
    var name: String
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
	struct Binary {
		var header: Header
		
		@Offset(givenBy: \Self.header.arm9Offset)
		@Length(givenBy: \Self.header.arm9Size)
		var arm9: Datastream
		@Count(givenBy: \Self.header.arm9OverlaySize, .dividedBy(32))
		@Offset(givenBy: \Self.header.arm9OverlayOffset)
		var arm9OverlayTable: [OverlayTableEntry]
		
		@Offset(givenBy: \Self.header.arm7Offset)
		@Length(givenBy: \Self.header.arm7Size)
		var arm7: Datastream
		@Count(givenBy: \Self.header.arm7OverlaySize, .dividedBy(32))
		@Offset(givenBy: \Self.header.arm7OverlayOffset)
		var arm7OverlayTable: [OverlayTableEntry]
		
		@Offset(givenBy: \Self.header.iconBannerOffset)
		@Length(0x840)
		var iconBanner: Datastream
		
		@Offset(givenBy: \Self.header.fileNameTableOffset)
		var fileNameTable: FileNameTable
		
		@Count(givenBy: \Self.header.fileAllocationTableSize, .dividedBy(8))
		@Offset(givenBy: \Self.header.fileAllocationTableOffset)
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

extension NDS: FileSystemObject {
    func savePath(in directory: URL) -> URL {
        Folder(name: name, contents: []).savePath(in: directory)
    }
    
    func write(into directory: URL) throws {
        let encoder = JSONEncoder(.prettyPrinted)
        
        let header           = Datastream(try encoder.encode(header))
        let arm9OverlayTable = Datastream(try encoder.encode(arm9OverlayTable))
        let arm7OverlayTable = Datastream(try encoder.encode(arm7OverlayTable))
        
        let contents: [any FileSystemObject] = [
            File  (name: "header.json",             data:     header),
            File  (name: "arm9",                    data:     arm9),
            File  (name: "arm9 overlay table.json", data:     arm9OverlayTable),
            Folder(name: "arm9 overlays",           contents: arm9Overlays),
            File  (name: "arm7",                    data:     arm7),
            File  (name: "arm7 overlay table.json", data:     arm7OverlayTable),
            Folder(name: "arm7 overlays",           contents: arm7Overlays),
            File  (name: "icon banner",             data:     iconBanner),
            Folder(name: "data",                    contents: contents)
        ]
        
        try Folder(name: name, contents: contents).write(into: directory)
    }
    
    func packed() -> PackedNDS {
        PackedNDS(
            name: name,
            binary: NDS.Binary(self)
        )
    }
    
    consuming func unpacked() throws -> Self {
        contents = try contents.map { try $0.unpacked() }
        return self
    }
}

struct PackedNDS: FileSystemObject {
    var name: String
    var binary: NDS.Binary
    
    static let fileExtension = "nds"
    
    func savePath(in directory: URL) -> URL {
        directory
            .appending(component: name)
            .appendingPathExtension(Self.fileExtension)
    }
    
    func write(into directory: URL) throws {
        let data = Datawriter()
        data.write(binary)
        
        try File(name: name + ".nds", data: Datastream(data.bytes))
            .write(into: directory)
    }
    
    func packed() -> Self { self }
    
    func unpacked() throws -> NDS {
        try NDS(name: name, binary: binary).unpacked()
    }
}


// MARK: packed
extension NDS {
    init(name: String, binary: Binary) throws {
        self.name = name
		header = binary.header
		
		arm9 = binary.arm9
		arm9OverlayTable = binary.arm9OverlayTable
		arm9Overlays = arm9OverlayTable.map {
			File(
				name: "overlay \($0.fileId).bin",
				data: binary.files[Int($0.fileId)]
			)
		}
		
		arm7 = binary.arm7
		arm7OverlayTable = binary.arm7OverlayTable
		arm7Overlays = arm7OverlayTable.map {
			File(
				name: "overlay \($0.fileId).bin",
				data: binary.files[Int($0.fileId)]
			)
		}
		
		iconBanner = binary.iconBanner
        
		let completeTable = binary.fileNameTable.completeTable()
		contents = try completeTable[0xF000]!.map {
			try $0.createFileSystemObject(files: binary.files, fileNameTable: completeTable)
		}
	}
}

extension NDS.Binary {
	init(_ nds: NDS) {
		header = nds.header
		
		arm9 = nds.arm9
		arm9OverlayTable = nds.arm9OverlayTable
		
		arm7 = nds.arm7
		arm7OverlayTable = nds.arm7OverlayTable
		
		iconBanner = nds.iconBanner
		
		let numberOfOverlays = UInt16(arm9OverlayTable.count + arm7OverlayTable.count)
		fileNameTable = FileNameTable(nds.contents, firstFileId: numberOfOverlays)
		
		let overlays = nds.arm9Overlays.sorted(by: \.name) + nds.arm7Overlays.sorted(by: \.name)
		let allFiles = overlays + nds.contents.getAllFiles()
        files = allFiles.map {
            let writer = Datawriter()
            switch $0 {
                case let file as File:
                    file.data.packed().write(to: writer)
                case let mar as MAR:
                    mar.packed().binary.write(to: writer)
                case let packedMAR as PackedMAR:
                    packedMAR.binary.write(to: writer)
                default:
                    fatalError("unexpected FileSystemObject type: \(type(of: $0))")
            }
            return writer.intoDatastream()
        }
		
		// TODO: doesnt account for FNT or FAT sizes change
		// crashes if file/folder added while unpacked
		
		header.arm9Offset =                                                    header.headerSize              .roundedUpToTheNearest(4)
		header.arm9OverlayOffset =         (header.arm9Offset                + header.arm9Size)               .roundedUpToTheNearest(4)
		header.arm7Offset =                (header.arm9OverlayOffset         + header.arm9OverlaySize)        .roundedUpToTheNearest(4)
		header.arm7OverlayOffset =         (header.arm7Offset                + header.arm7Size)               .roundedUpToTheNearest(4)
		header.fileNameTableOffset =       (header.arm7OverlayOffset         + header.arm7OverlaySize)        .roundedUpToTheNearest(4)
		header.fileAllocationTableOffset = (header.fileNameTableOffset       + header.fileNameTableSize)      .roundedUpToTheNearest(4)
		header.iconBannerOffset =          (header.fileAllocationTableOffset + header.fileAllocationTableSize).roundedUpToTheNearest(4)
		let filesOffset =                  (header.iconBannerOffset          + 0x840)                         .roundedUpToTheNearest(4)
		
		let fileSizes = files.map(\.bytes.count).map(UInt32.init)
		fileAllocationTable = fileSizes.reduce(into: []) { fat, size in
			let startAddress = fat.last?.endAddress ?? filesOffset
			fat.append(
				FileAllocationTableEntry(
					startAddress: startAddress,
					endAddress: startAddress + size
				)
			)
		}
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
	
    init(name: String, contents: [any FileSystemObject]) throws {
        self.name = name
        
		guard let headerFile =           contents.getChild(named: "header") as? File,
			  let headerData = headerFile.data as? Datastream,
			  
			  let arm9File =             contents.getChild(named: "arm9") as? File,
			  let arm9Data = arm9File.data as? Datastream,
			  
			  let arm9OverlayTableFile = contents.getChild(named: "arm9 overlay table") as? File,
			  let arm9OverlayTableData = arm9OverlayTableFile.data as? Datastream,
			  
			  let arm9OverlaysFolder =   contents.getChild(named: "arm9 overlays") as? Folder,
			  
			  let arm7File =             contents.getChild(named: "arm7") as? File,
			  let arm7Data = arm7File.data as? Datastream,
			  
			  let arm7OverlayTableFile = contents.getChild(named: "arm7 overlay table") as? File,
			  let arm7OverlayTableData = arm7OverlayTableFile.data as? Datastream,
			  
			  let arm7OverlaysFolder =   contents.getChild(named: "arm7 overlays") as? Folder,
			  
		      let iconBannerFile =       contents.getChild(named: "icon banner") as? File,
			  let iconBannerData = iconBannerFile.data as? Datastream,
			  
			  let dataFolder =           contents.getChild(named: "data") as? Folder else {
			throw UnpackingError.invalidFolderStructure(contents.map(\.name))
		}
		
        header = try JSONDecoder().decode(NDS.Binary.Header.self, from: Data(headerData.bytes))
		
		arm9 = arm9Data
        arm9OverlayTable = try JSONDecoder().decode([NDS.Binary.OverlayTableEntry].self, from: Data(arm9OverlayTableData.bytes))
		arm9Overlays = arm9OverlaysFolder.contents.compactMap { $0 as? File }
		
		arm7 = arm7Data
        arm7OverlayTable = try JSONDecoder().decode([NDS.Binary.OverlayTableEntry].self, from: Data(arm7OverlayTableData.bytes))
		arm7Overlays = arm7OverlaysFolder.contents.compactMap { $0 as? File }
		
		iconBanner = iconBannerData
		
        self.contents = dataFolder.contents
	}
}
