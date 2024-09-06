import ArgumentParser
import Foundation

import BinaryParser

@main
struct Carbonizer: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "A Fossil Fighters ROM-hacking tool.",
		discussion: "By default, carbonizer automatically determines whether to pack or unpack each input. It does this by looking at file extensions, magic bytes, and metadata"
	)
	
	@Flag(help: "Manually specify compression mode")
	var compressionMode: CompressionMode?
	
	@Argument(help: "The files to pack/unpack", transform: URL.fromFilePath)
	var filePaths = [URL]()
	
	enum CompressionMode: String, EnumerableFlag {
		case pack, unpack, ask
		
		static func name(for value: Self) -> NameSpecification {
			.shortAndLong
		}
	}
	
	mutating func run() async throws {
		do {
			try main()
//			try await monitor()
		} catch {
			print(error)
			waitForInput()
		}
	}
	
	mutating func main() throws {
#if !IN_CI
		filePaths.append(URL(filePath: "/Users/simonomi/ff1/Fossil Fighters.nds"))
//		filePaths.append(URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters"))
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
		
		let configurationFile = URL(filePath: "config.json")
		let extractModels = configurationFile.exists()
		
		for filePath in filePaths {
			logProgress("Reading \(filePath.path(percentEncoded: false))")
			let file = try createFileSystemObject(contentsOf: filePath)
			
#if IN_CI
			let processedFile: any FileSystemObject
#else
			var processedFile: any FileSystemObject
#endif
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
			
#if !IN_CI
			logProgress("running post-processors")
//			let inputFile = try createFileSystemObject(contentsOf: filePath).unpacked()
//			let allDialogue = dmgRipper(inputFile)
//			let file = dexDialogueLabeller(inputFile, dialogue: allDialogue)
//			let compressionMode = CompressionMode.unpack

//			processedFile = try processedFile.postProcessed(with: mmsFinder)
			processedFile = try processedFile.postProcessed(with: mm3Finder)
//			processedFile = try processedFile.postProcessed(with: mpmFinder) // doesnt work for much
			
//			file = try file.postProcessed(with: dexDialogueLabeller)
//			return
#endif
			
#if IN_CI
			if extractModels {
				processedFile = try processedFile.postProcessed(with: mm3Finder)
			}
			
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
