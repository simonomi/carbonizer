import BinaryParser
import Foundation

extension [NDS.Packed.Binary.FileNameTable.FolderContent]: BinaryConvertible {
	public init(_ data: inout Datastream) throws {
		self = []
		while last?.typeAndNameLength != 0 {
			append(try data.read(NDS.Packed.Binary.FileNameTable.FolderContent.self))
		}
		removeLast()
	}
	
	public func write(to data: BinaryParser.Datawriter) {
		forEach(data.write)
	}
}

extension Datawriter {
	func write(_ data: [NDS.Packed.Binary.FileNameTable.FolderContent]) {
		data.write(to: self)
	}
}

// folder id: content (with file id!)
typealias CompleteFNT = [UInt16: [NDS.Packed.Binary.FileNameTable.FolderContent]]

extension NDS.Packed.Binary.FileNameTable {
	func completeTable() -> CompleteFNT {
		let folderIds = (0..<rootFolder.totalFolderCount)
			.map { $0 + 0xF000 }
		
		let entries = zip([rootFolder] + folders, [rootContents] + folderContents)
			.map { folder, contents in
				var fileID = folder.firstChildId
				
				return contents.map {
					if $0.type == .file {
						defer { fileID += 1 }
						return $0.givenId(fileID)
					} else {
						return $0
					}
				}
			}
		
		return Dictionary(uniqueKeysWithValues: zip(folderIds, entries))
	}
}

extension NDS.Packed.Binary.FileNameTable.FolderContent {
	enum FileOrFolder { case file, folder }
	var type: FileOrFolder {
		if self.typeAndNameLength < 0x80 {
			.file
		} else {
			.folder
		}
	}
	
	var isFile: Bool {
		type == .file
	}
	
	func givenId(_ id: UInt16) -> Self {
		Self(typeAndNameLength: typeAndNameLength, name: name, id: id)
	}
	
	func fileSystemObject(
		files: [Datastream],
		fileNameTable: CompleteFNT,
		configuration: Configuration
	) throws -> any FileSystemObject {
		switch type {
			case .file:
				try makeFile(
					name: name,
					metadata: nil,
					data: files[Int(id!)],
					configuration: configuration
				)
			case .folder:
				Folder(
					name: name,
					contents: try fileNameTable[id!]!
						.map {
							try $0.fileSystemObject(
								files: files,
								fileNameTable: fileNameTable,
								configuration: configuration
							)
						}
				)
		}
	}
}

extension NDS.Packed.Binary.Header {
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

extension NDS.Packed.Binary.OverlayTableEntry {
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

extension NDS.Packed.Binary.FileNameTable {
	init(_ files: [any FileSystemObject], firstFileId: UInt16) {
		let allFolders = files.getAllFolders()
		let folderIds = Dictionary(
			uniqueKeysWithValues: allFolders
				.enumerated()
				.map { index, folder in
					(folder, UInt16(index + 0xF001))
				}
		)
		let foldersWithIds = folderIds
			.sorted(by: \.value)
			.map { folder, id in (folder: folder, id: id) }
		
		var fileId = firstFileId
		var contentsOffset = (folderIds.count + 1) * 8
		
		func makeFolderContents(_ fileSystemObject: any FileSystemObject) -> FolderContent {
			switch fileSystemObject {
				case is ProprietaryFile, is BinaryFile, is MAR.Unpacked, is MAR.Packed:
					fileId += 1
					contentsOffset += fileSystemObject.name.utf8CString.count
					return FolderContent(.file, name: fileSystemObject.name)
				case let folder as Folder:
					contentsOffset += folder.name.utf8CString.count + 2
					return FolderContent(.folder, name: folder.name, id: folderIds[folder]!)
				default:
					fatalError("unexpected FileSystemObject type: \(type(of: fileSystemObject))")
			}
		}
		
		rootFolder = FolderEntry(
			contentsOffset: UInt32(contentsOffset),
			firstChildId: fileId,
			parentId: UInt16(allFolders.count + 1)
		)
		rootContents = files.map(makeFolderContents) + [.end]
		contentsOffset += 1
		
		folders = []
		folderContents = []
		
		for folder in allFolders {
			let parentId = foldersWithIds.first {
				$0.folder.contents
					.compactMap(as: Folder.self)
					.contains { $0 == folder }
			}?.id ?? 0xF000
			
			folders.append(
				FolderEntry(
					contentsOffset: UInt32(contentsOffset),
					firstChildId: fileId,
					parentId: parentId
				)
			)
			folderContents.append(
				folder.contents
					.sorted(by: ffFileSort)
					.map(makeFolderContents) + [.end]
			)
			contentsOffset += 1
		}
	}
	func size() -> Int {
		FolderEntry.size +
		folders.size +
		rootContents.map(\.size).sum() +
		folderContents
			.flatMap { $0.map(\.size) }
			.sum()
	}
}

extension NDS.Packed.Binary.FileNameTable.FolderEntry {
	static let size = 8
}

extension [NDS.Packed.Binary.FileNameTable.FolderEntry] {
	var size: Int {
		count * NDS.Packed.Binary.FileNameTable.FolderEntry.size
	}
}

extension NDS.Packed.Binary.FileNameTable.FolderContent {
	var size: Int {
		// no null byte so count is +1
		switch type {
			case .file: name.utf8CString.count
			case .folder: name.utf8CString.count + 2
		}
	}
}

extension NDS.Packed.Binary.FileNameTable.FolderContent {
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
		sorted(by: ffFileSort)
		.flatMap {
			switch $0 {
				case let proprietaryFile as ProprietaryFile: [proprietaryFile]
				case let binaryFile as BinaryFile: [binaryFile]
				case let mar as MAR.Unpacked: [mar]
				case let packedMAR as MAR.Packed: [packedMAR]
				case let folder as Folder:
					folder.contents.getAllFiles()
				default:
					fatalError("unexpected FileSystemObject type: \(type(of: $0))")
			}
		}
	}
	
	func getAllFolders() -> [Folder] {
		sorted(by: ffFileSort)
		.compactMap(as: Folder.self)
			.flatMap { [$0] + $0.contents.getAllFolders() }
	}
}

fileprivate func ffFileSort(_ left: any FileSystemObject, _ right: any FileSystemObject) -> Bool {
	left.name.isFFLessThan(right.name)
}

fileprivate extension String {
	// so "." < "0" < "_" < "a" < "A" < "b"
	func isFFLessThan(_ other: String) -> Bool {
		for (character, otherCharacter) in zip(self, other) {
			guard character.lowercased() != otherCharacter.lowercased() else { continue }
			
			return if character == "." {
				true
			} else if otherCharacter == "." {
				false
			} else if character.isNumber != otherCharacter.isNumber {
				character.isNumber
			} else if character.isPunctuation != otherCharacter.isPunctuation {
				character.isPunctuation
			} else {
				character.lowercased() < otherCharacter.lowercased()
			}
		}
		
		return count < other.count
	}
}
