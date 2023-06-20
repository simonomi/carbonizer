//
//  main.swift
//
//
//  Created by simon pellerin on 2023-06-15.
//

import Foundation

var arguments = CommandLine.arguments.dropFirst()

#if DEBUG
//arguments.append("~/Fossil Fighters.nds")
//arguments.append("~/Fossil Fighters carbon")
//arguments.append("~/Downloads/ff1/roms/Fossil Fighters")
//arguments.append("~/Downloads/ff1/roms/Fossil Fighters/data/auto_battle/auto_battle")
#endif

if arguments.isEmpty {
	print("Please provide at least one file or folder as input")
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
		print("Error: file or folder does not exist: \(fileUrl.lastPathComponent)")
		continue
	}
	
	let fileType: FileManager.FileType
	do {
		fileType = try FileManager.type(of: fileUrl)
	} catch {
		print("Error: could not get type of file or folder: \(fileUrl.lastPathComponent)")
		continue
	}
	
	if fileType == .folder {
		print("Processing folder \(fileUrl.lastPathComponent)")
		
		let folder: FSFile
		do {
			folder = try FSFile(from: fileUrl)
		} catch {
			print("Error: could not read folder: \(fileUrl.lastPathComponent), \(error)")
			continue
		}
		
		// TODO: do this differently
		let outputPath = fileUrl.deletingLastPathComponent()
		try! folder.save(in: outputPath, carbonized: true)
	} else {
		print("Processing file \(fileUrl.lastPathComponent)")
		
		let file: FSFile
		do {
			file = try FSFile(from: fileUrl)
		} catch {
			print("Error: could not read file: \(fileUrl.lastPathComponent), \(error)")
			continue
		}
		
		// TODO: do this differently
		let outputPath = fileUrl.deletingLastPathComponent()
		try! file.save(in: outputPath, carbonized: false)
	}
}
