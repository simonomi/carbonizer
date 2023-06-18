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
#endif

if arguments.isEmpty {
	let contents: [URL]
	do {
		contents = try FileManager.default.contentsOfDirectory(at: .currentDirectory())
	} catch {
		print("Error: could not read current directory")
		exit(EXIT_FAILURE)
	}
	
	let ndsFiles = contents.filter { $0.pathExtension == "nds" }.map(\.lastPathComponent)
	
	if ndsFiles.isEmpty {
		print("Error: no nds files in current directory")
		exit(EXIT_FAILURE)
	}
	
	print("Found nds files:")
	for (index, file) in ndsFiles.enumerated() {
		print(" [\(index + 1)] \(file)")
	}
	
	print("Pick an nds file as input: ", terminator: "")
	
	guard let ndsIndex = readLine().flatMap(Int.init),
		  let ndsFile = ndsFiles.element(at: ndsIndex - 1) else {
		print("Error: index out of bounds")
		exit(EXIT_FAILURE)
	}
	arguments.append(ndsFile)
}

for file in arguments {
	let fileUrl: URL
	if file.hasPrefix("~") {
		fileUrl = URL.homeDirectory.appending(component: file.dropFirst(2))
	} else {
		fileUrl = URL(filePath: file)
	}
	
	if fileUrl.pathExtension != "nds" {
		print("Error: file does not end with .nds: \(fileUrl.lastPathComponent)")
		continue
	}
	
	let data: Data
	do {
		data = try Data(contentsOf: fileUrl)
	} catch {
		print("Error: file does not exist: \(fileUrl.lastPathComponent)")
		continue
	}
	
	print("parsing file \(fileUrl.lastPathComponent)")
	
	let binaryFile = BinaryFile(name: fileUrl.lastPathComponent, contents: data)
	let ndsFile = try! NDSFile(from: binaryFile)
	
//	let folder = try! Folder(from: ndsFile)
	
//	let NDSFileFromFolder = try! NDSFile(from: folder)
//	print(String(reflecting: ndsFile) == String(reflecting: NDSFileFromFolder))
	
	let newBinaryFile = try! BinaryFile(from: ndsFile)
//	print(binaryFile.contents == newBinaryFile.contents)
	
//	print("NOT SAVING REENCODED IDIOT")
	print("saving reencoded")
	try newBinaryFile.contents.write(to: .homeDirectory.appending(components: "Downloads", "ff1", "roms", "reencoded.nds"))
	
//	let NDSFileFromBinary = try! NDSFile(from: newBinaryFile)
//	print(String(reflecting: ndsFile.contents) == String(reflecting: NDSFileFromBinary.contents))
}
