//
//  File.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

enum File {
	case folder(Folder)
	case binaryFile(BinaryFile)
	case ndsFile(NDSFile)
	case marArchive(MARArchive)
//	case dtxFile(DTXFile)
	
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
}
