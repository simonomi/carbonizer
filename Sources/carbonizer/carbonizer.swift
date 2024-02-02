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
//		let ndsFilePath = URL(filePath: "/Users/simonomi/ff1/Fossil Fighters.nds")
//
//		let data = Datastream(try Data(contentsOf: ndsFilePath))
//
//		let initialNDSBinary = try data.read(NDS.Binary.self)
//		
//		let nds = try NDS(packed: initialNDSBinary)
//		
//		let remadeNDSBinary = nds.toPacked()
//		
////		printAllocations(of: initialNDSBinary)
//		printAllocations(of: remadeNDSBinary)
//		
//		return
		
		filePaths.append(URL(filePath: "/Users/simonomi/ff1/Fossil Fighters.nds"))
//		filePaths.append(URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters.nds"))
		filePaths.append(URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters"))
		
		for filePath in filePaths {
			let start = Date.now
			let file = try CreateFileSystemObject(contentsOf: filePath)
			print(-start.timeIntervalSinceNow)
			
			let inputWasPacked = filePath.absoluteString.hasSuffix("nds")
			
			let writeStart = Date.now
			try file.write(into: URL(filePath: "/Users/simonomi/ff1/output/"), packed: !inputWasPacked)
			print(-writeStart.timeIntervalSinceNow)
		}
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
