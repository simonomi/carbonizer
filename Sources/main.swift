//
//  main.swift
//
//
//  Created by simon pellerin on 2023-06-15.
//

import Foundation

var arguments = CommandLine.arguments.dropFirst()

#if DEBUG
arguments.append("~/Fossil Fighters.nds")
//arguments.append("~/Fossil Fighters carbon")
//arguments.append("~/Downloads/ff1/roms/Fossil Fighters")
//arguments.append("~/Downloads/ff1/roms/Fossil Fighters/data/auto_battle/auto_battle")
#endif

if arguments.isEmpty {
	print("Please provide at least one file as input")
	exit(EXIT_FAILURE)
}

for file in arguments {
	let fileUrl: URL
	if file.hasPrefix("~") {
		fileUrl = URL.homeDirectory.appending(component: file.dropFirst(2))
	} else {
		fileUrl = URL(filePath: file)
	}
	
	if !FileManager.default.fileExists(atPath: fileUrl.path(percentEncoded: false)) {
		print("Error: file does not exist: \(fileUrl.lastPathComponent)")
		continue
	}
	
	let fileType: FileManager.FileType
	do {
		fileType = try FileManager.type(of: fileUrl)
	} catch {
		print("Error: could not get type of file: \(fileUrl.lastPathComponent)")
		continue
	}
	
	if fileType == .folder {
		print("Processing folder \(fileUrl.lastPathComponent)")
		
		// TODO: handle
		let folder = try Folder(from: fileUrl)
		
		// TODO: do other things
		let ndsFile = try! NDSFile(from: folder)
		let binaryFile = try! BinaryFile(from: ndsFile)
		
		let outputPath = fileUrl.deletingLastPathComponent()
		try binaryFile.save(in: outputPath)
	} else {
		print("Processing file \(fileUrl.lastPathComponent)")
		
		let data: Data
		do {
			data = try Data(contentsOf: fileUrl)
		} catch {
			print("Error: could not read file: \(fileUrl.lastPathComponent)")
			continue
		}
		
		let binaryFile = BinaryFile(name: fileUrl.lastPathComponent, contents: data)
		
		// TODO: do other things
		let ndsFile = try! NDSFile(from: binaryFile)
		let folder = try! Folder(from: ndsFile)
		
		let arc = folder.getAllBinaryFiles().first { $0.name == "arc" }!
		print(try MARArchive(from: arc))
		
//		let outputPath = fileUrl.deletingLastPathComponent()
//		try folder.save(in: outputPath)
	}
}
