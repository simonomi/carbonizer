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
//	case dtxFile(DTXFile)
//	case mm3File(MM3File)
	
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
			default: break
		}
		
		switch magicId {
			case "MAR\0":
				inputIsCarbonized = true
				self = .marArchive(try MARArchive(named: name, from: data))
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
					let mcmFile = MCMFile(from: try File(from: path), with: metadata)
					self = .file(.marArchive(MARArchive(name: path.lastPathComponent, contents: [mcmFile])), nil)
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
		}
	}
}
