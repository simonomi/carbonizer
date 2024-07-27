import ArgumentParser
import Foundation

import BinaryParser

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
		case pack, unpack, ask
		
		static func name(for value: Self) -> NameSpecification {
			.shortAndLong
		}
	}
	
	mutating func run() throws {
		do {
			try main()
		} catch {
			print(error)
			waitForInput()
		}
	}
	
	mutating func main() throws {
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
        
        

#if !IN_CI
//		filePaths.append(URL(filePath: "/Users/simonomi/ff1/Fossil Fighters.nds"))
		filePaths.append(URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters"))
//		filePaths.append(URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters.nds"))
		
//		filePaths.append(URL(filePath: "/Users/simonomi/ff1/Fossil Fighters - Champions.nds"))
//		filePaths.append(URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters - Champions"))
//		filePaths.append(URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters - Champions.nds"))
#endif
		
		if filePaths.isEmpty {
			var standardError = FileHandle.standardError
			print("\(.red, .bold)Error:\(.normal) \(.bold)No files were specified as input\(.normal)", terminator: "\n\n", to: &standardError)
			print(Self.helpMessage())
			waitForInput()
			return
		}
		
		for filePath in filePaths {
            // TODO: document this
//			let extractMARsOptionFile = URL.currentDirectory().appending(component: "extract mars.txt")
//            if let extractMARsOverride = (try? String(contentsOf: extractMARsOptionFile))
//                .flatMap(ExtractMARs.init) {
//                await globalMutableState.replaceAutoExtractMARs(with: extractMARsOverride)
//            }
            
			logProgress("Reading \(filePath.path(percentEncoded: false))")
			let file = try createFileSystemObject(contentsOf: filePath)
			
#if !IN_CI
//			file = try file.postProcessed(with: mm3Finder)
//			file = try file.postProcessed(with: mpmFinder) // doesnt work for much
//			file = try file.postProcessed(with: mmsFinder)
//			return
#endif
			
			let processedFile: any FileSystemObject
            switch (compressionMode, file.packedStatus()) {
                case (.unpack, _), (nil, .packed):
                    processedFile = try file.unpacked()
                case (.pack, _), (nil, .unpacked):
                    processedFile = file.packed()
                default:
                    print("Would you like to [p]ack or [u]npack? ")
                    let answer = readLine()?.lowercased()
                    
                    if answer?.starts(with: "p") == true {
                        processedFile = file.packed()
                    } else if answer?.starts(with: "u") == true {
                        processedFile = try file.unpacked()
                    } else {
                        print("Skipping file...")
                        continue
                    }
            }
			
#if IN_CI
			let outputDirectory = filePath.deletingLastPathComponent()
#else
			let outputDirectory = URL(filePath: "/Users/simonomi/ff1/output/")
#endif
			
			let savePath = processedFile.savePath(in: outputDirectory).path(percentEncoded: false)
			logProgress("Writing to \(savePath)")
			
            try processedFile.write(into: outputDirectory)
		}
	}
}
