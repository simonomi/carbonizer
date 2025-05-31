import BinaryParser
import Foundation

enum NDS {
	struct Packed {
		var name: String
		var binary: Binary
		
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
	
	struct Unpacked {
		var name: String
		var header: NDS.Packed.Binary.Header
		
		var arm9: Datastream
		var arm9OverlayTable: [NDS.Packed.Binary.OverlayTableEntry]
		var arm9Overlays: [BinaryFile]
		
		var arm7: Datastream
		var arm7OverlayTable: [NDS.Packed.Binary.OverlayTableEntry]
		var arm7Overlays: [BinaryFile]
		
		var iconBanner: Datastream
		
		var contents: [any FileSystemObject]
	}
}

// MARK: packed
extension NDS.Packed: FileSystemObject {
	static let fileExtension = ".nds"
	
	func savePath(in directory: URL, overwriting: Bool) -> URL {
		BinaryFile(
			name: name + Self.fileExtension,
			data: Datastream()
		).savePath(in: directory, overwriting: overwriting)
	}
	
	func write(
		into path: URL,
		overwriting: Bool,
		with configuration: CarbonizerConfiguration
	) throws {
		let writer = Datawriter()
		writer.write(binary)
		
		do {
			try BinaryFile(
				name: name + Self.fileExtension,
				data: writer.intoDatastream()
			)
			.write(into: path, overwriting: overwriting, with: configuration)
		} catch {
			throw BinaryParserError.whileWriting(Self.self, error)
		}
	}
	
	func packedStatus() -> PackedStatus { .packed }
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(path: [String] = [], configuration: CarbonizerConfiguration) throws -> NDS.Unpacked {
		try NDS.Unpacked(name: name, binary: binary, configuration: configuration)
			.unpacked(configuration: configuration)
	}
}

extension NDS.Packed.Binary {
	init(_ unpacked: NDS.Unpacked, configuration: CarbonizerConfiguration) {
		header = unpacked.header
		
		arm9 = unpacked.arm9
		arm9OverlayTable = unpacked.arm9OverlayTable
		
		arm7 = unpacked.arm7
		arm7OverlayTable = unpacked.arm7OverlayTable
		
		iconBanner = unpacked.iconBanner
		
		let contents = unpacked.contents.map { $0.packed(configuration: configuration) }
		
		let numberOfOverlays = UInt16(arm9OverlayTable.count + arm7OverlayTable.count)
		fileNameTable = FileNameTable(contents, firstFileId: numberOfOverlays)
		
		let overlays = unpacked.arm9Overlays.sorted(by: \.name) + unpacked.arm7Overlays.sorted(by: \.name)
		let allFiles = overlays + contents.getAllFiles()
		files = allFiles.map {
			let writer = Datawriter()
			switch $0 {
				case let proprietaryFile as ProprietaryFile:
					proprietaryFile.data.write(to: writer)
				case let binaryFile as BinaryFile:
					writer.write(binaryFile.data)
				case let packedMAR as MAR.Packed:
					writer.write(packedMAR.binary)
				case is MAR.Unpacked:
					fatalError("unpacked FileSystemObject type \(MAR.self) should never be stored in a packed nds")
				default:
					fatalError("unexpected FileSystemObject type: \(type(of: $0))")
			}
			return writer.intoDatastream()
		}
		
		precondition(files.count == header.fileAllocationTableSize / 8, "error: file(s) added while unpacked")
		
		let offsetIncrement: UInt32 = 256
		let iconBannerSize: UInt32 = 0x840
		
		// ok, the original ff1 rom has the following:
		// 0x004000 header size
		// 0x004000 arm9 offset
		// 0x0793D0 arm9 size
		// 0x07D400 arm9 overlay offset
		// 0x000100 arm9 overlay size
		// 0x119600 arm7 offset
		// 0x02434C arm7 size
		// 0x000000 arm7 overlay offset
		// 0x000000 arm7 overlay size
		// 0x13DA00 fnt offset
		// 0x016D5F fnt size
		// 0x154800 fat offset
		// 0x0102B8 fat size
		// 0x164C00 icon banner offset
		
		header.arm9Offset =                                                    header.headerSize              .roundedUpToTheNearest(offsetIncrement)
		header.arm9OverlayOffset =         (header.arm9Offset                + header.arm9Size)               .roundedUpToTheNearest(offsetIncrement)
		header.arm7Offset =                (header.arm9OverlayOffset         + header.arm9OverlaySize)        .roundedUpToTheNearest(offsetIncrement)
		header.arm7OverlayOffset =         (header.arm7Offset                + header.arm7Size)               .roundedUpToTheNearest(offsetIncrement)
		header.fileNameTableOffset =       (header.arm7OverlayOffset         + header.arm7OverlaySize)        .roundedUpToTheNearest(offsetIncrement)
		header.fileAllocationTableOffset = (header.fileNameTableOffset       + header.fileNameTableSize)      .roundedUpToTheNearest(offsetIncrement)
		header.iconBannerOffset =          (header.fileAllocationTableOffset + header.fileAllocationTableSize).roundedUpToTheNearest(offsetIncrement)
		let filesOffset =                  (header.iconBannerOffset          + iconBannerSize)                         .roundedUpToTheNearest(offsetIncrement)
		
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
extension NDS.Unpacked: FileSystemObject {
	func savePath(in directory: URL, overwriting: Bool) -> URL {
		Folder(name: name, contents: [])
			.savePath(in: directory, overwriting: overwriting)
	}
	
	func write(
		into path: URL,
		overwriting: Bool,
		with configuration: CarbonizerConfiguration
	) throws {
		let encoder = JSONEncoder(.prettyPrinted, .sortedKeys)
		
		let header           = Datastream(try encoder.encode(header))
		let arm9OverlayTable = Datastream(try encoder.encode(arm9OverlayTable))
		let arm7OverlayTable = Datastream(try encoder.encode(arm7OverlayTable))
		
		let contents: [any FileSystemObject] = [
			Folder(name: "arm9 overlays", contents: arm9Overlays),
			Folder(name: "arm7 overlays", contents: arm7Overlays),
			Folder(name: "data",          contents: contents),
			BinaryFile(name: "arm9",                    data: arm9),
			BinaryFile(name: "arm9 overlay table.json", data: arm9OverlayTable),
			BinaryFile(name: "arm7",                    data: arm7),
			BinaryFile(name: "arm7 overlay table.json", data: arm7OverlayTable),
			BinaryFile(name: "header.json",             data: header),
			BinaryFile(name: "icon banner",             data: iconBanner)
		]
		
		try Folder(name: name, contents: contents)
			.write(into: path, overwriting: overwriting, with: configuration)
	}
	
	func packedStatus() -> PackedStatus {
		contents
			.map { $0.packedStatus() }
			.reduce(.unpacked) { $0.combined(with: $1) }
	}
	
	func packed(configuration: CarbonizerConfiguration) -> NDS.Packed {
		NDS.Packed(
			name: name,
			binary: NDS.Packed.Binary(self, configuration: configuration)
		)
	}
	
	consuming func unpacked(path: [String] = [], configuration: CarbonizerConfiguration) throws -> Self {
		contents = try contents.map { try $0.unpacked(path: [], configuration: configuration) }
		return self
	}
	
	init(name: String, binary: NDS.Packed.Binary, configuration: CarbonizerConfiguration) throws {
		self.name = name
		header = binary.header
		
		arm9 = binary.arm9
		arm9OverlayTable = binary.arm9OverlayTable
		arm9Overlays = arm9OverlayTable.map {
			BinaryFile(
				name: "overlay \($0.fileId, digits: 2).bin",
				data: binary.files[Int($0.fileId)]
			)
		}
		
		arm7 = binary.arm7
		arm7OverlayTable = binary.arm7OverlayTable
		arm7Overlays = arm7OverlayTable.map {
			BinaryFile(
				name: "overlay \($0.fileId, digits: 2).bin",
				data: binary.files[Int($0.fileId)]
			)
		}
		
		iconBanner = binary.iconBanner
		
		do {
			let completeTable = binary.fileNameTable.completeTable()
			contents = try completeTable[0xF000]!.map {
				try $0.fileSystemObject(
					files: binary.files,
					fileNameTable: completeTable,
					configuration: configuration
				)
			}
		} catch {
			throw BinaryParserError.whileReading(Self.self, error)
		}
	}
}

extension [any FileSystemObject] {
	fileprivate func getChild(named name: String) -> (any FileSystemObject)? {
		first { $0.name == name }
	}
}

extension NDS.Unpacked {
	enum UnpackingError: Error {
		case invalidFolderStructure([String])
	}
	
	init(
		name: String,
		contents: [any FileSystemObject],
		configuration: CarbonizerConfiguration
	) throws {
		self.name = name
		
		guard let headerFile =           contents.getChild(named: "header.json") as? BinaryFile,
			  let arm9File =             contents.getChild(named: "arm9") as? BinaryFile,
			  let arm9OverlayTableFile = contents.getChild(named: "arm9 overlay table.json") as? BinaryFile,
			  let arm9OverlaysFolder =   contents.getChild(named: "arm9 overlays") as? Folder,
			  let arm7File =             contents.getChild(named: "arm7") as? BinaryFile,
			  let arm7OverlayTableFile = contents.getChild(named: "arm7 overlay table.json") as? BinaryFile,
			  let arm7OverlaysFolder =   contents.getChild(named: "arm7 overlays") as? Folder,
			  let iconBannerFile =       contents.getChild(named: "icon banner") as? BinaryFile,
			  let dataFolder =           contents.getChild(named: "data") as? Folder
		else {
			throw UnpackingError.invalidFolderStructure(contents.map(\.name))
		}
		
		let headerData = Data(headerFile.data.bytes)
		let arm9OverlayTableData = Data(arm9OverlayTableFile.data.bytes)
		let arm7OverlayTableData = Data(arm7OverlayTableFile.data.bytes)
		
		header = try JSONDecoder().decode(
			NDS.Packed.Binary.Header.self,
			from: headerData
		)
		
		arm9 = arm9File.data
		arm9OverlayTable = try JSONDecoder().decode(
			[NDS.Packed.Binary.OverlayTableEntry].self,
			from: arm9OverlayTableData
		)
		arm9Overlays = arm9OverlaysFolder.contents
			.compactMap(as: BinaryFile.self)
		
		arm7 = arm7File.data
		arm7OverlayTable = try JSONDecoder().decode(
			[NDS.Packed.Binary.OverlayTableEntry].self,
			from: arm7OverlayTableData
		)
		arm7Overlays = arm7OverlaysFolder.contents
			.compactMap(as: BinaryFile.self)
		
		iconBanner = iconBannerFile.data
		
		self.contents = dataFolder.contents
	}
}
