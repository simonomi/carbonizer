//
//  File.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

import Foundation

enum File {
	case binaryFile(BinaryFile)
	case ndsFile(NDSFile)
	case marArchive(MARArchive)
	case dtxFile(DTXFile)
	case dmgFile(DMGFile)
	case mm3File(MM3File)
	case dmsFile(DMSFile)
	case mpmFile(MPMFile)
	
	init(from path: URL) throws {
		let data = try Data(contentsOf: path)
		try self.init(named: path.lastPathComponent, from: data)
	}
	
	init(named name: String, from data: Data) throws {
		let fileExtension: String?
		if name.contains(".") {
			fileExtension = name.split(separator: ".").last.map(String.init)
		} else {
			fileExtension = nil
		}
		
		let magicId = String(bytes: data.prefix(4), encoding: .utf8)
		
		switch fileExtension {
			case "nds":
				inputIsCarbonized = true
				self = .ndsFile(try NDSFile(named: name, from: data))
				return
			case "dtx":
				inputIsCarbonized = false
				self = .dtxFile(try DTXFile(named: name, json: data))
				return
			case "dmg":
				inputIsCarbonized = false
				self = .dmgFile(try DMGFile(named: name, json: data))
				return
			case "mm3":
				inputIsCarbonized = false
				self = .mm3File(try MM3File(named: name, json: data))
				return
			case "dms":
				inputIsCarbonized = false
				self = .dmsFile(try DMSFile(named: name, json: data))
				return
			case "mpm":
				inputIsCarbonized = false
				self = .mpmFile(try MPMFile(named: name, json: data))
				return
			default: break
		}
		
		switch magicId {
			case "MAR\0":
				inputIsCarbonized = true
				self = .marArchive(try MARArchive(named: name, from: data))
				return
			case "DTX\0":
				inputIsCarbonized = true
				self = .dtxFile(try DTXFile(named: name, from: data))
				return
			case "DMG\0":
				inputIsCarbonized = true
				self = .dmgFile(try DMGFile(named: name, from: data))
				return
			case "MM3\0":
				inputIsCarbonized = true
				self = .mm3File(try MM3File(named: name, from: data))
				return
			case "DMS\0":
				inputIsCarbonized = true
				self = .dmsFile(try DMSFile(named: name, from: data))
				return
			case "MPM\0":
				inputIsCarbonized = true
				self = .mpmFile(try MPMFile(named: name, from: data))
				return
			default: break
		}
		
		self = .binaryFile(BinaryFile(named: name, contents: data))
	}
	
	func save(in path: URL, carbonized: Bool, with metadata: MCMFile.Metadata?) throws {
		switch self {
			case .binaryFile(let binaryFile):
				try binaryFile.save(in: path, carbonized: carbonized, with: metadata)
			case .ndsFile(let ndsFile):
				try ndsFile.save(in: path, carbonized: carbonized, with: metadata)
			case .marArchive(let marArchive):
				try marArchive.save(in: path, carbonized: carbonized, with: metadata)
			case .dtxFile(let dtxFile):
				try dtxFile.save(in: path, carbonized: carbonized, with: metadata)
			case .dmgFile(let dmgFile):
				try dmgFile.save(in: path, carbonized: carbonized, with: metadata)
			case .mm3File(let mm3File):
				try mm3File.save(in: path, carbonized: carbonized, with: metadata)
			case .dmsFile(let dmsFile):
				try dmsFile.save(in: path, carbonized: carbonized, with: metadata)
			case .mpmFile(let mpmFile):
				try mpmFile.save(in: path, carbonized: carbonized, with: metadata)
		}
	}
	
	var name: String {
		switch self {
			case .binaryFile(let binaryFile):
				return binaryFile.name
			case .ndsFile(let ndsFile):
				return ndsFile.name
			case .marArchive(let marArchive):
				return marArchive.name
			case .dtxFile(let dtxFile):
				return dtxFile.name
			case .dmgFile(let dmgFile):
				return dmgFile.name
			case .mm3File(let mm3File):
				return mm3File.name
			case .dmsFile(let dmsFile):
				return dmsFile.name
			case .mpmFile(let mpmFile):
				return mpmFile.name
		}
	}
	
	func renamed(to newName: String) -> File {
		switch self {
			case .binaryFile(var binaryFile):
				binaryFile.name = newName
				return .binaryFile(binaryFile)
			case .ndsFile(var ndsFile):
				ndsFile.name = newName
				return .ndsFile(ndsFile)
			case .marArchive(var marArchive):
				marArchive.name = newName
				return .marArchive(marArchive)
			case .dtxFile(var dtxFile):
				dtxFile.name = newName
				return .dtxFile(dtxFile)
			case .dmgFile(var dmgFile):
				dmgFile.name = newName
				return .dmgFile(dmgFile)
			case .mm3File(var mm3File):
				mm3File.name = newName
				return .mm3File(mm3File)
			case .dmsFile(var dmsFile):
				dmsFile.name = newName
				return .dmsFile(dmsFile)
			case .mpmFile(var mpmFile):
				mpmFile.name = newName
				return .mpmFile(mpmFile)
		}
	}
}

enum FSFile {
	case folder(Folder)
	case file(File, MCMFile.Metadata?)
	
	enum FileError: Error {
		case abnormalFiletype(URL)
	}
	
	init(from path: URL) throws {
		switch try FileManager.type(of: path) {
			case .typeDirectory:
				let folder = try Folder(from: path)
				if folder.name.hasSuffix(".mar") {
					inputIsCarbonized = false
					self = .file(.marArchive(try MARArchive(from: folder)), nil)
				} else if folder.getChild(named: "header.json") != nil {
					inputIsCarbonized = false
					self = .file(.ndsFile(try NDSFile(from: folder)), nil)
				} else {
					self = .folder(folder)
				}
			default:
				let metadata = try FileManager.getCreationDate(of: path).flatMap(MCMFile.Metadata.init)
				if let metadata, metadata.standalone {
					inputIsCarbonized = false
					let file = try File(from: path)
					let mcmFile = MCMFile(from: file, with: metadata)
					self = .file(.marArchive(MARArchive(name: file.name, contents: [mcmFile])), nil)
				} else {
					self = .file(try File(from: path), metadata)
				}
		}
	}
	
	func save(in path: URL, carbonized: Bool) throws {
		switch self {
			case .file(let file, let metadata):
				try file.save(in: path, carbonized: carbonized, with: metadata)
			case .folder(let folder):
				try folder.save(in: path, carbonized: carbonized)
		}
	}
	
	var name: String {
		switch self {
			case .folder(let folder):
				return folder.name
			case .file(let file, _):
				return file.name
		}
	}
}

extension Data {
	init(from file: File) throws {
		switch file {
			case .binaryFile(let binaryFile):
				self = binaryFile.contents
			case .ndsFile(let ndsFile):
				self = try Data(from: ndsFile)
			case .marArchive(let marArchive):
				self = try Data(from: marArchive)
			case .dtxFile(let dtxFile):
				self = try Data(from: dtxFile)
			case .dmgFile(let dmgFile):
				self = try Data(from: dmgFile)
			case .mm3File(let mm3File):
				self = try Data(from: mm3File)
			case .dmsFile(let dmsFile):
				self = try Data(from: dmsFile)
			case .mpmFile(let mpmFile):
				self = try Data(from: mpmFile)
		}
	}
}
