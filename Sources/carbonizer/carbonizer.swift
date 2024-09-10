import ArgumentParser
import Foundation

@main
struct Carbonizer: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "A Fossil Fighters ROM-hacking tool.",
		discussion: "By default, carbonizer automatically determines whether to pack or unpack each input. It does this by looking at file extensions, magic bytes, and metadata"
	)
	
	@Flag(help: "Manually specify compression mode (default: --auto)")
	var compressionMode: CarbonizerConfiguration.CompressionMode?
	
	@Argument(help: "The files to pack/unpack", transform: URL.fromFilePath)
	var filePaths = [URL]()
	
	mutating func run() async throws {
		let start = Date.now
		
		do {
#if IN_CI
			let configurationPath = URL(filePath: "config.json")
			let configuration = try CarbonizerConfiguration(contentsOf: configurationPath)
#else
			let configuration = CarbonizerConfiguration(
				compressionMode: .auto,
//				compressionMode: .unpack,
				inputFiles: [
					URL(filePath: "/Users/simonomi/ff1/Fossil Fighters.nds"),
//					URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters"),
//					URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters.nds"),
				],
				outputFolder: URL(filePath: "/Users/simonomi/ff1/output/"),
				overwriteOutput: true,
				fileTypes: ["DEX", "DMG", "DMS", "DTX", "MAR", "MM3", "MPM", "NDS", "RLS"],
//				skipExtracting: [],
//				onlyExtract: [],
				experimental: CarbonizerConfiguration.ExperimentalOptions(
					hotReloading: false,
					postProcessors: [
//						"mm3Finder"
					]
				)
			)
#endif
			
			filePaths += configuration.inputFiles
			
			if filePaths.isEmpty {
				var standardError = FileHandle.standardError
				print("\(.red, .bold)Error:\(.normal) \(.bold)No files were specified as input\(.normal)", terminator: "\n\n", to: &standardError)
				print(Self.helpMessage())
				waitForInput()
				return
			}
			
			if configuration.experimental.hotReloading {
				try await monitor(with: configuration)
			} else {
				try main(with: configuration)
			}
		} catch {
			print(error)
			waitForInput()
		}
		
		print(-start.timeIntervalSinceNow)
	}
	
	mutating func main(with configuration: CarbonizerConfiguration) throws {
		let compressionMode = compressionMode ?? configuration.compressionMode
		
		for filePath in filePaths {
			logProgress("Reading \(filePath.path(percentEncoded: false))")
			let file = try fileSystemObject(contentsOf: filePath, configuration: configuration)
			
			let action = compressionMode.action(packedStatus: file.packedStatus())
			
			var processedFile: any FileSystemObject
			switch action {
				case .pack:
					processedFile = file.packed()
				case .unpack:
					processedFile = try file.unpacked()
				case nil:
					print("Skipping file...")
					continue
			}
			
			logProgress("Running post-processors")
			let postProcessors: [String: PostProcessor] = [
				"mm3Finder": mm3Finder,
				"mmsFinder": mmsFinder,
				"mpmFinder": mpmFinder
			]
			
			for postProcessorName in configuration.experimental.postProcessors {
#if os(Windows)
				switch postProcessorName {
					case "mm3Finder":
						processedFile = try processedFile.postProcessed(with: mm3Finder)
					case "mmsFinder":
						processedFile = try processedFile.postProcessed(with: mmsFinder)
					case "mpmFinder":
						processedFile = try processedFile.postProcessed(with: mpmFinder)
					default:
						print("Could not find a post-processor named '\(postProcessorName)', skipping...")
						continue
				}
#else
				guard let postProcessor = postProcessors[postProcessorName] else {
					print("Could not find a post-processor named '\(postProcessorName)', skipping...")
					continue
				}
				
				processedFile = try processedFile.postProcessed(with: postProcessor)
#endif
			}
			
			let outputFolder = configuration.outputFolder ?? filePath.deletingLastPathComponent()
			
			let savePath = processedFile.savePath(
				in: outputFolder,
				overwriting: configuration.overwriteOutput
			)
			
			logProgress("Writing to \(savePath.path(percentEncoded: false))")
			
			if configuration.overwriteOutput && savePath.exists() {
				try FileManager.default.removeItem(at: savePath)
			}
			
			try processedFile.write(into: outputFolder, overwriting: configuration.overwriteOutput)
		}
	}
}
