//
//  textureLabeler.swift
//  
//
//  Created by simon pellerin on 2023-06-25.
//

var textureLabels = [String : Set<UInt32>]()

func textureLabeler(_ file: File, in parent: Folder) throws -> [FSFile] {
	if case .marArchive(let marArchive) = file,
	   case .mm3File(let mm3File) = marArchive.onlyChild?.content {
		let tablePath = "\(parent.name)/\(mm3File.tableNames.2)"
		textureLabels[tablePath, default: []].insert(mm3File.indexes.2)
	}
	return [.file(file)]
}

func textureParser(_ file: File, in parent: Folder) throws -> [FSFile] {
	let path = "\(parent.name)/\(file.name)"
	if case .marArchive(let marArchive) = file,
	   let textureIndexes = textureLabels[path] {
		return [.file(.marArchive(
			MARArchive(
				name: marArchive.name,
				contents: try marArchive.contents.map {
					guard textureIndexes.contains(UInt32($0.index)),
						  case .binaryFile(let binaryFile) = $0.content else { return $0 }
					return MCMFile(
						index: $0.index,
						compression: $0.compression,
						maxChunkSize: $0.maxChunkSize,
						content: .textureFile(try TextureFile(named: binaryFile.name, from: binaryFile.contents))
					)
				}
			)
		))]
	}
	return [.file(file)]
}
