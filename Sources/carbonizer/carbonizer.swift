import ArgumentParser
import Foundation

import BinaryParser

//actor GlobalMutableState {
//    var extractMARs: ExtractMARs = .auto
//    var inputPackedStatus = InputPackedStatus.unknown
//    
//    func setExtractMARs(to newValue: ExtractMARs) {
//        extractMARs = newValue
//    }
//    
//    func replaceAutoExtractMARs(with newValue: ExtractMARs) {
//        extractMARs.replaceAuto(with: newValue)
//    }
//}
//
//let globalMutableState = GlobalMutableState()

enum ExtractMARs: String, ExpressibleByArgument {
	case always, never, auto
	
	var shouldExtract: Bool {
		self == .always || self == .auto
	}
	
	mutating func replaceAuto(with newValue: Self) {
		if self == .auto {
			self = newValue
		}
	}
}

@main
struct Carbonizer: ParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "A Fossil Fighters ROM-hacking tool.",
		discussion: "By default, carbonizer automatically determines whether to pack or unpack each input. It does this by looking at file extensions, magic bytes, and metadata"
	)
	
	@Flag(help: "Manually specify compression mode")
	var compressionMode: CompressionMode?
	
	@Option(name: [.short, .customLong("extract-mars")], help: "Whether to extract MAR files. Options are always, never, auto")
	var extractMARsInput: ExtractMARs = .auto
	
	@Argument(help: "The files to pack/unpack", transform: URL.fromFilePath)
	var filePaths = [URL]()
	
	enum CompressionMode: String, EnumerableFlag {
		case pack, unpack
		
		static func name(for value: Self) -> NameSpecification {
			.shortAndLong
		}
	}
	
	mutating func run() throws {
//		let filePath = URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters/data/btl_ai/")
//
//		let contents = try filePath.contents()
//
//		let someses = try contents.flatMap {
//			let data = Datastream(try Data(contentsOf: $0))
//			let ais = try data.read(AIS.Binary.self)
//			return ais.somes
//		}
//
//		print(someses.map(\.unknown1).uniqued().sorted())
//		print(someses.map(\.unknown2).uniqued().sorted())
//
//		print(someses.map(\.unknown1).min()!)
//		print(someses.map(\.unknown1).max()!)
//		print(someses.map(\.unknown2).min()!)
//		print(someses.map(\.unknown2).max()!)
//
//
//		let filePath = URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters/data/btl_aiset/")
//
//		let contents = try filePath.contents()
//
//		let things = try contents.flatMap { file in
//			let data = Datastream(try Data(contentsOf: file))
//			let ast = try data.read(AST.Binary.self)
//
//			return ast.things
//		}
//
//		print(things.map { $0.indices[0] }.uniqued().sorted())
//		print(things.map { $0.indices[1] }.uniqued().sorted())
//		print(things.map { $0.indices[2] }.uniqued().sorted())
//		print(things.map { $0.indices[3] }.uniqued().sorted())
//		print(things.map { $0.indices[4] }.uniqued().sorted())
//		print(things.map { $0.indices[5] }.uniqued().sorted())
//
////		for thing in things.sorted(by: \.unknown1) {
////			print(thing.idks)
////		}
////
////		print(things.flatMap(\.idks).uniqued().sorted())
////		print(things.map(\.unknown1).uniqued().sorted())
//
//		return ()
        
        

        // TODO: debug only
		filePaths.append(URL(filePath: "/Users/simonomi/ff1/Fossil Fighters.nds"))
//		filePaths.append(URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters"))
//		filePaths.append(URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters.nds"))
//		filePaths.append(URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters repacked.nds"))
		
//        filePaths.append(URL(filePath: "/Users/simonomi/ff1/Fossil Fighters - Champions.nds"))
//		filePaths.append(URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters - Champions"))
		
//		await globalMutableState.setExtractMARs(to: extractMARsInput)
//
//		await globalMutableState.setExtractMARs(to: .always) // TODO: debug only
		
		if filePaths.isEmpty {
			var standardError = FileHandle.standardError
			print("\(.red, .bold)Error:\(.normal) \(.bold)No files were specified as input\(.normal)", terminator: "\n\n", to: &standardError)
			print(Self.helpMessage())
			waitForInput()
			return
		}
		
		for filePath in filePaths {
            // TODO: document this
			let extractMARsOptionFile = URL.currentDirectory().appending(component: "extract mars.txt")
//            if let extractMARsOverride = (try? String(contentsOf: extractMARsOptionFile))
//                .flatMap(ExtractMARs.init) {
//                await globalMutableState.replaceAutoExtractMARs(with: extractMARsOverride)
//            }
            
//			let start = Date.now
			let file = try createFileSystemObject(contentsOf: filePath)
//			print(-start.timeIntervalSinceNow)
			
//			file = try file.postProcessed(with: mm3Finder)
//			file = try file.postProcessed(with: mpmFinder) // doesnt work for much
//			file = try file.postProcessed(with: mmsFinder)
//			return
			
//			let unpackedFile = try file.unpacked()
			let unpackedFile = file.packed()
            print() // to clear progress
			
//			let writeStart = Date.now
//			let outputDirectory = filePath.deletingLastPathComponent()
			let outputDirectory = URL(filePath: "/Users/simonomi/ff1/output/")
			
			let savePath = unpackedFile.savePath(in: outputDirectory)
			if savePath.exists() {
				print("file \(savePath.path(percentEncoded: false)) already exists, do you want to replace it?")
//                try FileManager.default.removeItem(at: savePath) // TODO: dont do this
				// or possibly just add suffix
				Self.exit()
			}
			
            try unpackedFile.write(into: outputDirectory)
            
//			inputPackedStatus = .packed // TODO: debug only
			
//			if let wasPacked = inputWasPacked.wasPacked {
//				try file.write(into: outputDirectory, packed: !wasPacked)
//			} else {
//				print("Would you like to [P]ack or [U]npack? ")
//				guard let answer = readLine()?.lowercased() else { return }
//				
//				if answer.starts(with: "p") {
//					try file.write(into: outputDirectory, packed: true)
//				} else if answer.starts(with: "u") {
//					try file.write(into: outputDirectory, packed: false)
//				} else {
//					return
//				}
//			}
//			print(-writeStart.timeIntervalSinceNow)
		}
	}
}
