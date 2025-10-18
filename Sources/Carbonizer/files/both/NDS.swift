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
			struct Header {
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
				var rootFolder: FolderEntry
				
				@Count(givenBy: \Self.rootFolder.totalFolderCount, .minus(1))
				var folders: [FolderEntry]
				
				@Offset(givenBy: \Self.rootFolder.contentsOffset)
				var rootContents: [FolderContent]
				
				@Offsets(givenBy: \Self.folders, at: \.contentsOffset)
				var folderContents: [[FolderContent]]
				
				@BinaryConvertible
				struct FolderEntry {
					var contentsOffset: UInt32
					var firstChildId: UInt16
					var parentId: UInt16 // for first entry, number of folders instead of parent id
					
					// for clarity at use-site
					var totalFolderCount: UInt16 { parentId }
				}
				
				@BinaryConvertible
				struct FolderContent {
					var typeAndNameLength: UInt8
					@Length(givenBy: \Self.typeAndNameLength, .modulo(0x80))
					var name: String
					@If(\Self.type, is: .equalTo(.folder))
					var id: UInt16?
				}
			}
			
			@BinaryConvertible
			struct FileAllocationTableEntry: Codable {
				var startAddress: UInt32
				var endAddress: UInt32
			}
		}
	}
	
	struct Unpacked {
		var name: String
		var header: Header
		
		var arm9: Datastream
		var arm9OverlayTable: [NDS.Packed.Binary.OverlayTableEntry]
		var arm9Overlays: [BinaryFile]
		
		var arm7: Datastream
		var arm7OverlayTable: [NDS.Packed.Binary.OverlayTableEntry]
		var arm7Overlays: [BinaryFile]
		
		var iconBanner: Datastream
		
		// file name table somehow...
//		var fileAllocationTable: [NDS.Packed.Binary.FileAllocationTableEntry]
		
		var contents: [any FileSystemObject]
		
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
			var reserved3: Data
			
			var carbonizerVersion: String
			var fileTypes: Set<String>
		}
	}
}

// MARK: packed
extension NDS.Packed: FileSystemObject {
	static let fileExtension = ".nds"
	
	func savePath(in directory: URL, with configuration: Configuration) -> URL {
		BinaryFile(
			name: name + Self.fileExtension,
			data: Datastream()
		).savePath(in: directory, with: configuration)
	}
	
	func write(
		into path: URL,
		with configuration: Configuration
	) throws {
		let writer = Datawriter()
		writer.write(binary)
		
		do {
			try BinaryFile(
				name: name + Self.fileExtension,
				data: writer.intoDatastream()
			)
			.write(into: path, with: configuration)
		} catch {
			throw BinaryParserError.whileWriting(Self.self, error)
		}
	}
	
	func packedStatus() -> PackedStatus { .packed }
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(path: [String] = [], configuration: Configuration) throws -> NDS.Unpacked {
		try NDS.Unpacked(name: name, binary: binary, configuration: configuration)
			.unpacked(configuration: configuration)
	}
}

extension NDS.Packed.Binary {
	init(_ unpacked: NDS.Unpacked, configuration: Configuration) throws {
		header = Header(unpacked.header)
		
		arm9 = unpacked.arm9
		arm9OverlayTable = unpacked.arm9OverlayTable
		
		arm7 = unpacked.arm7
		arm7OverlayTable = unpacked.arm7OverlayTable
		
		iconBanner = unpacked.iconBanner
		
		let contents = try unpacked.contents.map { try $0.packed(configuration: configuration) }
		
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
		
//		print(zip(allFiles, files).map { ($0.name, $1.bytes.count) })
		
		precondition(files.count == header.fileAllocationTableSize / 8, "error: file(s) added while packing")
		
		let offsetIncrement: UInt32 = 0x200
		let iconBannerSize: UInt32 = 0x840
		
		// ok, the original ff1 rom has the following:
		// 0x004000 header size
		// 0x004000 arm9 offset
		// 0x0793D0 arm9 size
		// 0x07D400 arm9 overlay offset
		// 0x000100 arm9 overlay size
		// overlays
		// 0x119600 arm7 offset
		// 0x02434C arm7 size
		// 0x000000 arm7 overlay offset
		// 0x000000 arm7 overlay size
		// 0x13DA00 fnt offset
		// 0x016D5F fnt size
		// 0x154800 fat offset
		// 0x0102B8 fat size
		// 0x164C00 icon banner offset
		
		// TODO: file order is actually NOT just alphabetical
		// - the original ROM sorts in a different way than swift (_ < A)
		
		// ok plan:
		// - add setting for filling with 0xFF
		// - enable compression
		// - store fnt and fat
		// - if all sizes are <= original, fit everything into the same places
		// - otherwise, move file(s) to the first available location (probably the end), based on which ends up with least displacement
		
		
		// keep these from the original rom
		// TODO: make sure no sizes have changed
//		header.arm9Offset =                                                    header.headerSize              .roundedUpToTheNearest(offsetIncrement)
//		header.arm9OverlayOffset =         (header.arm9Offset                + header.arm9Size)               .roundedUpToTheNearest(offsetIncrement)
//		header.arm7Offset =                (header.arm9OverlayOffset         + header.arm9OverlaySize)        .roundedUpToTheNearest(offsetIncrement)
//		header.arm7OverlayOffset =         (header.arm7Offset                + header.arm7Size)               .roundedUpToTheNearest(offsetIncrement)
//		header.fileNameTableOffset =       (header.arm7OverlayOffset         + header.arm7OverlaySize)        .roundedUpToTheNearest(offsetIncrement)
//		header.fileAllocationTableOffset = (header.fileNameTableOffset       + header.fileNameTableSize)      .roundedUpToTheNearest(offsetIncrement)
//		header.iconBannerOffset =          (header.fileAllocationTableOffset + header.fileAllocationTableSize).roundedUpToTheNearest(offsetIncrement)
		
		let filesOffset = (header.iconBannerOffset + iconBannerSize)
			.roundedUpToTheNearest(offsetIncrement)
		
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

extension NDS.Packed.Binary.Header {
	init(_ unpacked: NDS.Unpacked.Header) {
		gameTitle = unpacked.gameTitle
		gamecode = unpacked.gamecode
		makercode = unpacked.makercode
		unitcode = unpacked.unitcode
		encryptionSeedSelect = unpacked.encryptionSeedSelect
		deviceCapacity = unpacked.deviceCapacity
		reserved1 = Datastream(unpacked.reserved1)
		ndsRegion = unpacked.ndsRegion
		romVersion = unpacked.romVersion
		internalFlags = unpacked.internalFlags
		arm9Offset = unpacked.arm9Offset
		arm9EntryAddress = unpacked.arm9EntryAddress
		arm9LoadAddress = unpacked.arm9LoadAddress
		arm9Size = unpacked.arm9Size
		arm7Offset = unpacked.arm7Offset
		arm7EntryAddress = unpacked.arm7EntryAddress
		arm7LoadAddress = unpacked.arm7LoadAddress
		arm7Size = unpacked.arm7Size
		fileNameTableOffset = unpacked.fileNameTableOffset
		fileNameTableSize = unpacked.fileNameTableSize
		fileAllocationTableOffset = unpacked.fileAllocationTableOffset
		fileAllocationTableSize = unpacked.fileAllocationTableSize
		arm9OverlayOffset = unpacked.arm9OverlayOffset
		arm9OverlaySize = unpacked.arm9OverlaySize
		arm7OverlayOffset = unpacked.arm7OverlayOffset
		arm7OverlaySize = unpacked.arm7OverlaySize
		normalCardControlRegisterSettings = unpacked.normalCardControlRegisterSettings
		secureCardControlRegisterSettings = unpacked.secureCardControlRegisterSettings
		iconBannerOffset = unpacked.iconBannerOffset
		secureAreaCRC = unpacked.secureAreaCRC
		secureTransferTimeout = unpacked.secureTransferTimeout
		arm9Autoload = unpacked.arm9Autoload
		arm7Autoload = unpacked.arm7Autoload
		secureDisable = unpacked.secureDisable
		totalROMSize = unpacked.totalROMSize
		headerSize = unpacked.headerSize
		reserved2 = Datastream(unpacked.reserved2)
		nintendoLogo = Datastream(unpacked.nintendoLogo)
		nintendoLogoCRC = unpacked.nintendoLogoCRC
		headerCRC = unpacked.headerCRC
		reserved3 = Datastream(unpacked.reserved3)
	}
}

// MARK: unpacked
extension NDS.Unpacked: FileSystemObject {
	func savePath(in directory: URL, with configuration: Configuration) -> URL {
		Folder(name: name, contents: [])
			.savePath(in: directory, with: configuration)
	}
	
	func write(
		into path: URL,
		with configuration: Configuration
	) throws {
		let encoder = JSONEncoder(.prettyPrinted, .sortedKeys)
		
		let header           = Datastream(try encoder.encode(header))
		let arm9OverlayTable = Datastream(try encoder.encode(arm9OverlayTable))
		let arm7OverlayTable = Datastream(try encoder.encode(arm7OverlayTable))
		
		let contents: [any FileSystemObject] = [
			Folder(name: "_arm9 overlays", contents: arm9Overlays),
			Folder(name: "_arm7 overlays", contents: arm7Overlays),
			BinaryFile(name: "arm9",                    data: arm9),
			BinaryFile(name: "arm9 overlay table.json", data: arm9OverlayTable),
			BinaryFile(name: "arm7",                    data: arm7),
			BinaryFile(name: "arm7 overlay table.json", data: arm7OverlayTable),
			BinaryFile(name: "header.json",             data: header),
			BinaryFile(name: "icon banner",             data: iconBanner)
		] + contents
		
		try Folder(name: name, contents: contents)
			.write(into: path, with: configuration)
	}
	
	func packedStatus() -> PackedStatus { .unpacked }
	
	func packed(configuration: Configuration) throws -> NDS.Packed {
		NDS.Packed(
			name: name,
			binary: try NDS.Packed.Binary(self, configuration: configuration)
		)
	}
	
	consuming func unpacked(path: [String] = [], configuration: Configuration) throws -> Self {
		contents = try contents.map { try $0.unpacked(path: [], configuration: configuration) }
		return self
	}
	
	init(name: String, binary: NDS.Packed.Binary, configuration: Configuration) throws {
		self.name = name
		header = Header(binary.header, configuration: configuration)
		
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
			
			if contents.contains(where: { $0.name == "battle_param" }) {
				configuration.ensureGame(is: .ffc)
			} else {
				configuration.ensureGame(is: .ff1)
			}
		} catch {
			throw BinaryParserError.whileReading(Self.self, error)
		}
	}
}

extension NDS.Unpacked.Header {
	init(_ packed: NDS.Packed.Binary.Header, configuration: Configuration) {
		gameTitle = packed.gameTitle
		gamecode = packed.gamecode
		makercode = packed.makercode
		unitcode = packed.unitcode
		encryptionSeedSelect = packed.encryptionSeedSelect
		deviceCapacity = packed.deviceCapacity
		reserved1 = Data(packed.reserved1)
		ndsRegion = packed.ndsRegion
		romVersion = packed.romVersion
		internalFlags = packed.internalFlags
		arm9Offset = packed.arm9Offset
		arm9EntryAddress = packed.arm9EntryAddress
		arm9LoadAddress = packed.arm9LoadAddress
		arm9Size = packed.arm9Size
		arm7Offset = packed.arm7Offset
		arm7EntryAddress = packed.arm7EntryAddress
		arm7LoadAddress = packed.arm7LoadAddress
		arm7Size = packed.arm7Size
		fileNameTableOffset = packed.fileNameTableOffset
		fileNameTableSize = packed.fileNameTableSize
		fileAllocationTableOffset = packed.fileAllocationTableOffset
		fileAllocationTableSize = packed.fileAllocationTableSize
		arm9OverlayOffset = packed.arm9OverlayOffset
		arm9OverlaySize = packed.arm9OverlaySize
		arm7OverlayOffset = packed.arm7OverlayOffset
		arm7OverlaySize = packed.arm7OverlaySize
		normalCardControlRegisterSettings = packed.normalCardControlRegisterSettings
		secureCardControlRegisterSettings = packed.secureCardControlRegisterSettings
		iconBannerOffset = packed.iconBannerOffset
		secureAreaCRC = packed.secureAreaCRC
		secureTransferTimeout = packed.secureTransferTimeout
		arm9Autoload = packed.arm9Autoload
		arm7Autoload = packed.arm7Autoload
		secureDisable = packed.secureDisable
		totalROMSize = packed.totalROMSize
		headerSize = packed.headerSize
		reserved2 = Data(packed.reserved2)
		nintendoLogo = Data(packed.nintendoLogo)
		nintendoLogoCRC = packed.nintendoLogoCRC
		headerCRC = packed.headerCRC
		reserved3 = Data(packed.reserved3)
		
		carbonizerVersion = Carbonizer.version
		fileTypes = configuration.fileTypes
	}
}

extension [any FileSystemObject] {
	fileprivate func getChild(named name: String) -> (any FileSystemObject)? {
		first { $0.name == name }
	}
}

extension NDS.Unpacked {
	enum UnpackingError: Error, CustomStringConvertible {
		case invalidFolderStructure([String])
		case filesAdded(expectedCount: UInt32, actualCount: Int)
		case wrongVersion(String)
		case missingFileTypes(Set<String>)
		
		var description: String {
			switch self {
				case .invalidFolderStructure(let contentNames):
					"invalid folder structure: \(contentNames)"
				case .filesAdded(expectedCount: let expectedCount, actualCount: let actualCount):
					"file(s) added while unpacked (expected \(.green)\(expectedCount)\(.normal), got \(.red)\(actualCount)\(.normal)"
				case .wrongVersion(let version):
					"this ROM was unpacked with a different version of carbonizer (\(.red)\(version)\(.normal)), repack it with that version, then unpack it with this one (\(.green)\(Carbonizer.version)\(.normal))"
				case .missingFileTypes(let fileTypes):
					{
						let fileTypeNames = fileTypes
							.sorted()
							.map { "\(.red)\($0)\(.normal)" }
							.joined(separator: ", ")
						
						let sIfPlural = fileTypes.count == 1 ? "" : "s"
						let itOrThem = fileTypes.count == 1 ? "it" : "them"
						
						return "this ROM was unpacked with the \(fileTypeNames) file type\(sIfPlural), enable \(itOrThem) to repack it"
					}()
			}
		}
	}
	
	init(
		name: String,
		contents: [any FileSystemObject],
		configuration: Configuration
	) throws {
		self.name = name
		
		guard let headerFile =           contents.getChild(named: "header.json") as? BinaryFile,
			  let arm9File =             contents.getChild(named: "arm9") as? BinaryFile,
			  let arm9OverlayTableFile = contents.getChild(named: "arm9 overlay table.json") as? BinaryFile,
			  let arm9OverlaysFolder =   contents.getChild(named: "_arm9 overlays") as? Folder,
			  let arm7File =             contents.getChild(named: "arm7") as? BinaryFile,
			  let arm7OverlayTableFile = contents.getChild(named: "arm7 overlay table.json") as? BinaryFile,
			  let arm7OverlaysFolder =   contents.getChild(named: "_arm7 overlays") as? Folder,
			  let iconBannerFile =       contents.getChild(named: "icon banner") as? BinaryFile
		else {
			throw UnpackingError.invalidFolderStructure(contents.map(\.name))
		}
		
		let headerData = Data(headerFile.data.bytes)
		let arm9OverlayTableData = Data(arm9OverlayTableFile.data.bytes)
		let arm7OverlayTableData = Data(arm7OverlayTableFile.data.bytes)
		
		header = try JSONDecoder().decode(Header.self, from: headerData)
		
		guard header.carbonizerVersion == Carbonizer.version else {
			throw UnpackingError.wrongVersion(header.carbonizerVersion)
		}
		
		let missingFileTypes = header.fileTypes.subtracting(configuration.fileTypes)
		guard missingFileTypes.isEmpty else {
			throw UnpackingError.missingFileTypes(missingFileTypes)
		}
		
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
		
		self.contents = contents.filter {
			!["header.json", "arm9", "arm9 overlay table.json", "_arm9 overlays", "arm7", "arm7 overlay table.json", "_arm7 overlays", "icon banner"].contains($0.name)
		}
		
		let expectedFileCount = header.fileAllocationTableSize / 8
		let actualFileCount = arm9Overlays.count + arm7Overlays.count + self.contents.getAllFiles().count
		
		guard actualFileCount == expectedFileCount else {
			throw UnpackingError.filesAdded(expectedCount: expectedFileCount, actualCount: actualFileCount)
		}
	}
}

fileprivate extension Configuration {
	func ensureGame(is game: Game) {
		if self.game != game {
			log(.warning, "it looks like you're trying to unpack \(.green)\(game)\(.normal), but the configuration is set to \(.red)\(self.game)\(.normal)")
		}
	}
}
