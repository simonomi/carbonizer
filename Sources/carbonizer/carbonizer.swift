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
		filePaths.append(URL(filePath: "/Users/simonomi/ff1/Fossil Fighters.nds"))
		
		for filePath in filePaths {
//			let file = File(filePath: filePath)
//			print(file)
			
			print("starting")
			let datastream = Datastream(try Data(contentsOf: filePath))
			
			let start = Date.now
			let nds = try NDS(packed: datastream)
			print(-start.timeIntervalSinceNow)
			
			print(nds.contents.count)
			print(nds.contents.map(\.name))
		}
	}
}
