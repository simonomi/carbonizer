//
//  main.swift
//
//
//  Created by simon pellerin on 2023-06-15.
//

import Foundation

var arguments = CommandLine.arguments.dropFirst()
var inputIsCarbonized = false

#if DEBUG
//arguments.append("fast")
arguments.append("~/Fossil Fighters.nds")
arguments.append("~/Fossil Fighters carbon")
#endif

let fastMode = arguments.first == "fast"
if fastMode {
	arguments.removeFirst()
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
		waitToExit()
		continue
	}
	
	print("Processing \(fileUrl.lastPathComponent)")
	
	var file: FSFile
	do {
		file = try FSFile(from: fileUrl)
	} catch {
		print("Error: could not read file: \(fileUrl.lastPathComponent), \(error)")
		waitToExit()
		continue
	}
	
#if DEBUG
	if case .file(let ndsFile, _) = file, ndsFile.name == "Fossil Fighters" {
		file = .file(ndsFile.renamed(to: "Fossil Fighters carbon"))
		
		try? FileManager.default.removeItem(at: .homeDirectory.appendingPathComponent("Fossil Fighters carbon"))
		try? FileManager.default.removeItem(at: .homeDirectory.appendingPathComponent("Fossil Fighters carbon.nds"))
	}
#endif
	
//	let _ = try! file.postProcessed(with: textureLabeler)
//	file = try! file.postProcessed(with: textureParser)
	
	if inputIsCarbonized {
		file = file.postProcessed(with: nameClarifier)
	} else {
		file = file.postProcessed(with: nameObfuscator)
	}
	
	let outputPath = fileUrl.deletingLastPathComponent()
	do {
		try file.save(in: outputPath, carbonized: !inputIsCarbonized)
	} catch {
		print("Error: could not save file: \(fileUrl.lastPathComponent), \(error)")
		waitToExit()
		continue
	}
}
