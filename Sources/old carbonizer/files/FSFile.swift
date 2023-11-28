//
//  FSFile.swift
//
//
//  Created by simon pellerin on 2023-06-22.
//

import Foundation

enum FSFile {
	case folder(Folder)
	case file(File, MCMFile.Metadata? = nil)
	
	enum FileError: Error {
		case abnormalFiletype(URL)
	}
	
	init(from path: URL) throws {
		switch try FileManager.type(of: path) {
			case .typeDirectory:
				let folder = try Folder(from: path)
				if folder.name.hasSuffix(".mar") {
					inputIsCarbonized = false
					self = .file(.marArchive(try MARArchive(from: folder)))
				} else if folder.getChild(named: "header.json") != nil {
					inputIsCarbonized = false
					self = .file(.ndsFile(try NDSFile(from: folder)))
				} else {
					self = .folder(folder)
				}
			default:
				let metadata = try FileManager.getCreationDate(of: path).flatMap(MCMFile.Metadata.init)
				if let metadata, metadata.standalone {
					inputIsCarbonized = false
					let file = try File(from: path)
					let mcmFile = MCMFile(from: file, with: metadata)
					self = .file(.marArchive(MARArchive(name: file.name, contents: [mcmFile])))
				} else {
					self = .file(try File(from: path), metadata)
				}
		}
	}
	
	func save(in path: URL, carbonized: Bool) throws {
		switch self {
			case .folder(let folder):
				try folder.save(in: path, carbonized: carbonized)
			case .file(let file, let metadata):
				try file.save(in: path, carbonized: carbonized, with: metadata)
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
