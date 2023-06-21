//
//  main.swift
//
//
//  Created by simon pellerin on 2023-06-15.
//

import Foundation

var arguments = CommandLine.arguments.dropFirst()
var inputIsCarbonized = false

//#if DEBUG
//arguments.append("~/Fossil Fighters.nds")
//arguments.append("~/Fossil Fighters carbon")
//arguments.append("~/Downloads/ff1/roms/Fossil Fighters")
//arguments.append("~/Downloads/ff1/roms/Fossil Fighters/data/auto_battle/auto_battle")
//#endif

func waitToExit() {
	print("Press Enter to continue...", terminator: "")
	let _ = readLine()
}

if arguments.isEmpty {
	print("Please provide at least one file or folder as input")
	waitToExit()
	exit(EXIT_FAILURE)
}

for file in arguments {
	let fileUrl: URL
	if file.hasPrefix("~") {
		fileUrl = URL.homeDirectory.appendingPathComponent(String(file.dropFirst(2)))
	} else {
		fileUrl = URL(fileURLWithPath: file)
	}
	
	if !FileManager.default.fileExists(atPath: fileUrl.path) {
		print("Error: file or folder does not exist: \(fileUrl.lastPathComponent)")
		continue
	}
	
	print("Processing \(fileUrl.lastPathComponent)")
	
	let file: FSFile
	do {
		file = try FSFile(from: fileUrl)
	} catch {
		print("Error: could not read file: \(fileUrl.lastPathComponent), \(error)")
		continue
	}
	
	let outputPath = fileUrl.deletingLastPathComponent()
	do {
		try file.save(in: outputPath, carbonized: !inputIsCarbonized)
	} catch {
		print("Error: could not save file: \(fileUrl.lastPathComponent), \(error)")
		continue
	}
}

waitToExit()
