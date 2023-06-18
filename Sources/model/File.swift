//
//  File.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

import Foundation

enum File {
	case folder(Folder)
	case binaryFile(BinaryFile)
	case ndsFile(NDSFile)
	case marArchive(MARArchive)
//	case mcmFile(MCMFile)
//	case dtxFile(DTXFile)
//	case mm3File(MM3File)
	
	var name: String {
		switch self {
			case .folder(let folder):
				return folder.name
			case .binaryFile(let binaryFile):
				return binaryFile.name
			case .ndsFile(let nDSFile):
				return nDSFile.name
			case .marArchive(let mARArchive):
				return mARArchive.name
		}
	}
	
	func carbonized() throws -> FSFile {
		switch self {
			case .folder(let folder):
				return try folder.carbonized()
			case .binaryFile(let binaryFile):
				return try binaryFile.carbonized()
			case .ndsFile(let nDSFile):
				return try nDSFile.carbonized()
			case .marArchive(let mARArchive):
				return try mARArchive.carbonized()
		}
	}
	
	func uncarbonized() throws -> FSFile {
		switch self {
			case .folder(let folder):
				return try folder.uncarbonized()
			case .binaryFile(let binaryFile):
				return try binaryFile.uncarbonized()
			case .ndsFile(let nDSFile):
				return try nDSFile.uncarbonized()
			case .marArchive(let mARArchive):
				return try mARArchive.uncarbonized()
		}
	}
}

enum FSFile {
	case binaryFile(BinaryFile)
	case folder(Folder)
	
	var asFile: File {
		switch self {
			case .binaryFile(let binaryFile):
				return .binaryFile(binaryFile)
			case .folder(let folder):
				return .folder(folder)
		}
	}
	
	func save(in path: URL) throws {
		switch self {
			case .binaryFile(let binaryFile):
				try binaryFile.save(in: path)
			case .folder(let folder):
				try folder.save(in: path)
		}
	}
}
