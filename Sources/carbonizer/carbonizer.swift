//
//  carbonizer.swift
//
//
//  Created by alice on 2023-11-25.
//

import ArgumentParser
import Foundation

// TODO: remove
import BinaryParser

@main
struct carbonizer: ParsableCommand {
	static var configuration = CommandConfiguration(
		abstract: "A Fossil Fighters ROM-hacking tool.",
		discussion: "By default, carbonizer automatically determines whether to pack or unpack each input. It does this by looking at file extensions, magic bytes, and metadata"
	)
	
	@Flag(help: "Manually specify compression mode")
	var compressionMode: CompressionMode?
	
	@Flag(name: .shortAndLong, help: "TODO: Fast mode")
	var fast = false
	
	@Argument(help: "The files to pack/unpack.", transform: URL.fromFilePath)
	var filePaths = [URL]()
	
	enum CompressionMode: String, EnumerableFlag {
		case pack, unpack
		
		static func name(for value: Self) -> NameSpecification {
			.shortAndLong
		}
	}
	
	mutating func run() throws {
		let dalFilePath = URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters/data/etc/attack_defs.bin")
		
		let data = Datastream(try Data(contentsOf: dalFilePath))
		
		let dal = try data.read(DAL.Binary.self)
		print(dal)
		
		
		return
		
//		filePaths.append(URL(filePath: "/Users/simonomi/ff1/Fossil Fighters.nds"))
		filePaths.append(URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters.nds"))
//		filePaths.append(URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters"))
		
		for filePath in filePaths {
			let start = Date.now
			let file = try CreateFileSystemObject(contentsOf: filePath)
			print(-start.timeIntervalSinceNow)
			
			let writeStart = Date.now
			try file.write(into: URL(filePath: "/Users/simonomi/ff1/output/"), packed: true)
			print(-writeStart.timeIntervalSinceNow)
		}
		
//		let original = URL(filePath: "/Users/simonomi/ff1/Fossil Fighters.nds")
//		let originalFile = try CreateFileSystemObject(contentsOf: original)
//		try originalFile.write(into: URL(filePath: "/Users/simonomi/ff1/output/"), packed: true)
		
//		let datastream = Datastream(try Data(contentsOf: original))
//		let ndsBinary = try NDS.Binary(datastream)
//		
//		let datawriter = Datawriter()
//		ndsBinary.write(to: datawriter)
//		
//		let product = URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters.nds")
//		try datawriter.write(to: product)
//		let productFile = try CreateFileSystemObject(contentsOf: product)
	}
}

//extension FileSystemObject {
//	func forEachFile(_ body: (File) -> Void) {
//		switch self {
//			case let file as File:
//				body(file)
//			case let folder as Folder:
//				folder.files.forEach { $0.forEachFile(body) }
//			default:
//				fatalError()
//		}
//	}
//}
