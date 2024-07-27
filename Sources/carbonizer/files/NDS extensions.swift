import BinaryParser
import Foundation

#if compiler(>=6)
extension [NDS.Binary.FileNameTable.SubEntry]: @retroactive BinaryConvertible {
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
#else
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
#endif

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
				let (name, fileExtension) = splitFileName(name)
				
				return try createFile(
					name: name,
					fileExtension: fileExtension,
					metadata: nil,
					data: files[Int(id!)]
				)
			case .folder:
				return Folder(
					name: name,
					contents: try fileNameTable[id!]!
						.map {
							try $0.createFileSystemObject(files: files, fileNameTable: fileNameTable)
						}
				)
		}
	}
}

extension NDS.Binary.Header {
	enum CodingKeys: String, CodingKey {
		case gameTitle =                         "game title"
		case gamecode =                          "gamecode"
		case makercode =                         "makercode"
		case unitcode =                          "unitcode"
		case encryptionSeedSelect =              "encryption seed select"
		case deviceCapacity =                    "device capacity"
		case reserved1 =                         "reserved (1)"
		case ndsRegion =                         "NDS region"
		case romVersion =                        "ROM version"
		case internalFlags =                     "internal flags"
		case arm9Offset =                        "arm9 offset"
		case arm9EntryAddress =                  "arm9 entry address"
		case arm9LoadAddress =                   "arm9 load address"
		case arm9Size =                          "arm9 size"
		case arm7Offset =                        "arm7 offset"
		case arm7EntryAddress =                  "arm7 entry address"
		case arm7LoadAddress =                   "arm7 load address"
		case arm7Size =                          "arm7 size"
		case fileNameTableOffset =               "file name table offset"
		case fileNameTableSize =                 "file name table size"
		case fileAllocationTableOffset =         "file allocation table offset"
		case fileAllocationTableSize =           "file allocation table size"
		case arm9OverlayOffset =                 "arm9 overlay offset"
		case arm9OverlaySize =                   "arm9 overlay size"
		case arm7OverlayOffset =                 "arm7 overlay offset"
		case arm7OverlaySize =                   "arm7 overlay size"
		case normalCardControlRegisterSettings = "normal card control register settings"
		case secureCardControlRegisterSettings = "secure card control register settings"
		case iconBannerOffset =                  "icon banner offset"
		case secureAreaCRC =                     "secure area (2K) CRC"
		case secureTransferTimeout =             "secure transfer timeout"
		case arm9Autoload =                      "arm9 autoload"
		case arm7Autoload =                      "arm7 autoload"
		case secureDisable =                     "secure disable"
		case totalROMSize =                      "total ROM size"
		case headerSize =                        "header size"
		case reserved2 =                         "reserved (2)"
		case nintendoLogo =                      "Nintendo logo"
		case nintendoLogoCRC =                   "Nintendo logo CRC"
		case headerCRC =                         "header CRC"
		case reserved3 =                         "reserved (3)"
	}
}

extension NDS.Binary.OverlayTableEntry {
	enum CodingKeys: String, CodingKey {
		case id =                                "overlay ID"
		case loadAddress =                       "load address"
		case ramSize =                           "RAM size"
		case bssSize =                           "BSS size"
		case staticInitializerStartAddress =     "static initialiser start address"
		case staticInitializerEndAddress =       "static initialiser end address"
		case fileId =                            "file ID"
		case reserved =                          "reserved"
	}
}

extension NDS.Binary.FileNameTable {
	init(_ files: [any FileSystemObject], firstFileId: UInt16) {
		let allFolders = files.getAllFolders()
		let folderIds = Dictionary(uniqueKeysWithValues:
									allFolders
			.enumerated()
			.map { index, folder in
				(folder, UInt16(index + 0xF001))
			}
		)
		let foldersWithIds = folderIds
			.sorted(by: \.value)
			.map { folder, id in (folder: folder, id: id) }
		
		var fileId = firstFileId
		var subTableOffset = (folderIds.count + 1) * 8
		
		func createSubEntry(_ fileSystemObject: any FileSystemObject) -> SubEntry {
			switch fileSystemObject {
				case is ProprietaryFile, is BinaryFile, is MAR, is PackedMAR:
					fileId += 1
					subTableOffset += fileSystemObject.fullName.utf8CString.count
					return SubEntry(.file, name: fileSystemObject.fullName)
				case let folder as Folder:
					subTableOffset += folder.fullName.utf8CString.count + 2
					return SubEntry(.folder, name: folder.fullName, id: folderIds[folder]!)
				default:
					fatalError("unexpected FileSystemObject type: \(type(of: fileSystemObject))")
			}
		}
		
		rootFolder = MainEntry(
			subTableOffset: UInt32(subTableOffset),
			firstChildId: fileId,
			parentId: UInt16(allFolders.count + 1)
		)
		rootSubTable = files.map(createSubEntry) + [.end]
		subTableOffset += 1
		
		mainTable = []
		subTables = []
		
		for folder in allFolders {
			let parentId = foldersWithIds.first {
				$0.folder.contents
					.compactMap(as: Folder.self)
					.contains { $0 == folder }
			}?.id ?? 0xF000
			
			mainTable.append(
				MainEntry(
					subTableOffset: UInt32(subTableOffset),
					firstChildId: fileId,
					parentId: parentId
				)
			)
			subTables.append(folder.contents.map(createSubEntry) + [.end])
			subTableOffset += 1
		}
	}
}

extension NDS.Binary.FileNameTable.SubEntry {
	init(_ type: FileOrFolder, name: String, id: UInt16? = nil) {
		let typeModifier = type == .folder ? 0x80 : 0
		typeAndNameLength = UInt8(name.utf8.count + typeModifier)
		self.name = name
		self.id = id
	}
	
	static let end = Self(.file, name: "")
}

extension [any FileSystemObject] {
	func getAllFiles() -> [any FileSystemObject] {
		flatMap {
			switch $0 {
				case let proprietaryFile as ProprietaryFile: [proprietaryFile]
				case let binaryFile as BinaryFile: [binaryFile]
				case let mar as MAR: [mar]
				case let packedMAR as PackedMAR: [packedMAR]
				case let folder as Folder:
					folder.contents.getAllFiles()
				default:
					fatalError("unexpected FileSystemObject type: \(type(of: $0))")
			}
		}
	}
	
	func getAllFolders() -> [Folder] {
		compactMap(as: Folder.self)
			.flatMap { [$0] + $0.contents.getAllFolders() }
	}
}
