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
#if !IN_CI
		let start = Date.now
#endif
		
#if !IN_CI && os(macOS)
		let configurationPath = URL(filePath: "/Users/simonomi/Desktop/config.json5")
#else
#if os(Windows)
		let configurationFileExtension = "json"
#else
		let configurationFileExtension = "json5"
#endif
		
		// TODO: dont let this just fallback, show an error if theres no url?
		let configurationPath = Bundle.main.executableURL?
			.deletingLastPathComponent()
			.appending(component: "config.\(configurationFileExtension)") ?? URL(filePath: "config.\(configurationFileExtension)")
#endif
		
		let configuration: CarbonizerConfiguration
		do {
			configuration = try CarbonizerConfiguration(contentsOf: configurationPath)
		} catch let error as DecodingError {
			print(error.configurationFormatting(path: configurationPath))
			waitForInput()
			return
		} catch {
			print("\(.bold)\(configurationPath.path(percentEncoded: false))\(.normal): \(error)")
			waitForInput()
			return
		}
		
		do {
			filePaths += configuration.inputFiles.map { URL(filePath: $0) }
			
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
			if configuration.useColor {
				print("\(.red)error:\(.normal)", error)
			} else {
				print("error:", String(describing: error).removingANSIFontEffects())
			}
			if configuration.keepWindowOpen.isTrueOnError {
				waitForInput()
			}
		}
		
#if !IN_CI
		print("\(.green)total", -start.timeIntervalSinceNow, "\(.normal)")
#endif
	}
	
	mutating func main(with configuration: CarbonizerConfiguration) throws {
		let compressionMode = compressionMode ?? configuration.compressionMode
		
		for filePath in filePaths {
			logProgress(
				"Reading \(filePath.path(percentEncoded: false))",
				configuration: configuration
			)
			
#if !IN_CI
			let readStart = Date.now
#endif
			
			let file = try fileSystemObject(contentsOf: filePath, configuration: configuration)
			
#if !IN_CI
			print()
			print("\(.red)read", -readStart.timeIntervalSinceNow, "\(.normal)")
			
			let processStart = Date.now
#endif
			
			let action = compressionMode.action(packedStatus: file.packedStatus())
			
			var processedFile: any FileSystemObject
			switch action {
				case .pack:
					processedFile = file.packed(configuration: configuration)
				case .unpack:
					processedFile = try file.unpacked(path: [], configuration: configuration)
				case nil:
					print("Skipping file...")
					continue
			}
			
			logProgress(
				"Running post-processors",
				configuration: configuration
			)
//			let postProcessors: [String: PostProcessor] = [
//				"3clFinder": tclFinder,
//				"mm3Finder": mm3Finder,
//				"mmsFinder": mmsFinder,
//				"mpmFinder": mpmFinder
//			]
			
			for postProcessorName in configuration.experimental.postProcessors {
//#if os(Windows)
				switch postProcessorName {
					case "3clFinder":
						processedFile = try processedFile.postProcessed(with: tclFinder)
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
//#else
//				guard let postProcessor = postProcessors[postProcessorName] else {
//					print("Could not find a post-processor named '\(postProcessorName)', skipping...")
//					continue
//				}
//				
//				processedFile = try processedFile.postProcessed(with: postProcessor)
//#endif
			}
			
			if configuration.experimental.dexDialogueLabeller, action == .unpack {
				let dialogue = dmgRipper(processedFile)
				processedFile = dexDialogueLabeller(
					processedFile,
					dialogue: dialogue,
					configuration: configuration
				)
			}
			
			if configuration.experimental.dexBlockLabeller, action == .unpack {
				processedFile = dexBlockLabeller(
					processedFile,
					configuration: configuration
				)
			}
			
			if configuration.experimental.dbsNameLabeller, action == .unpack {
				let text = dtxRipper(processedFile)
				processedFile = dbsNameLabeller(
					processedFile,
					text: text,
					configuration: configuration
				)
			}
			
#if !IN_CI
			print()
			print("\(.yellow)process", -processStart.timeIntervalSinceNow, "\(.normal)")
#endif
			
			let outputFolder = configuration.outputFolder.map { URL(filePath: $0) } ?? filePath.deletingLastPathComponent()
			
			let savePath = processedFile.savePath(
				in: outputFolder,
				overwriting: configuration.overwriteOutput
			)
			
			logProgress(
				"Writing to \(savePath.path(percentEncoded: false))",
				configuration: configuration
			)
			
#if !IN_CI
			let removeStart = Date.now
			print()
#endif
			
			if configuration.overwriteOutput && savePath.exists() {
				try FileManager.default.removeItem(at: savePath)
				
#if !IN_CI
				print("\(.red)remove", -removeStart.timeIntervalSinceNow, "\(.normal)")
#endif
			}
			
#if !IN_CI
			let writeStart = Date.now
#endif
			
			try processedFile.write(
				into: outputFolder,
				overwriting: configuration.overwriteOutput,
				with: configuration
			)
			
#if !IN_CI
			print("\(.cyan)write", -writeStart.timeIntervalSinceNow, "\(.normal)")
#endif
		}
	}
}
