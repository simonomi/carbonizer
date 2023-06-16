//
//  File.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

protocol FileObject {
	var name: String { get }
	var metadata: [Metadata] { get }
}

enum Metadata {
	case ndsMetadata(NDSMetadata)
}

enum File {
	case folder(Folder)
	case binaryFile(BinaryFile)
	case ndsFile(NDSFile)
	case marArchive(MARArchive)
//	case dtxFile(DTXFile)
}
