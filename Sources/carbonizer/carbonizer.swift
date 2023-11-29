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
			let start = Date.now
			let file = try File(filePath: filePath)
			print(-start.timeIntervalSinceNow)
			
//			let nds = file.data as! NDS
//			let folder = nds.contents.last as! Folder
//			let english = folder.files.first as! File
//			let mar = english.data as! MAR
//			let mcm = mar.files.first!
//			let data = mcm.content as! Datastream
//			
//			print(english.name)
//			print(mcm)
			
//			print(data.bytes.count)
//			let onceDecompressed = try Huffman.decompress(data)
//			let decompressed = try LZSS.decompress(onceDecompressed)
//			print(onceDecompressed.bytes.count)
			
//			let dedata = Data(decompressed.bytes)
//			try dedata.write(to: URL(filePath: "/Users/simonomi/Desktop/out.bin"))
			
//			print(
//				decompressed.bytes
//					.map { String($0, radix: 16).padded(toLength: 2, with: "0") }
//					.joined(separator: " ")
//			)
			
//			var filetypes = Set<String>()
//			
//			nds.contents.forEach {
//				$0.forEachFile {
//					guard let mar = $0.data as? MAR else { return }
//					mar.files.forEach {
//						if type(of: $0.content) != Datastream.self {
//							print($0.content)
//							filetypes.insert(String(describing: type(of: $0.content)))
//						}
//					}
//				}
//			}
//			
//			print(filetypes)
		}
	}
}

extension FileSystemObject {
	func forEachFile(_ body: (File) -> Void) {
		switch self {
			case let file as File:
				body(file)
			case let folder as Folder:
				folder.files.forEach { $0.forEachFile(body) }
			default:
				fatalError()
		}
	}
}
