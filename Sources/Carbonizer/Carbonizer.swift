import ArgumentParser
import Foundation

// TODO: list
// - add a .carbonizer file or smthn to contain the version number
//   - if trying to pack from too old a version (semver or smthn), give an error
//   - also the list of file types, so if some file types were extracted they need to be repacked

@main
struct Carbonizer: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "A Fossil Fighters ROM-hacking tool",
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
				print("error:", String(describing: error).removingANSICodes())
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
			print("Reading \(filePath.path(percentEncoded: false))...")
			
#if !IN_CI
			let readStart = Date.now
#endif
			
			guard var file = try fileSystemObject(contentsOf: filePath, configuration: configuration) else {
				print("Skipping file...")
				continue
			}
			
			guard file is NDS.Packed || file is NDS.Unpacked else {
				throw InvalidInput()
			}
			
#if !IN_CI
			print("\(.red)read", -readStart.timeIntervalSinceNow, "\(.normal)\(.clearToEndOfLine)")
			
			let processStart = Date.now
#endif
			
			let action = compressionMode.action(packedStatus: file.packedStatus())
			
			if configuration.experimental.dexDialogueSaver, action == .pack {
				let updatedDialogueWithConflicts = try dexDialogueRipper(file)
				
				let updatedDialogue = updatedDialogueWithConflicts.mapValues {
					switch $0 {
						case .one(let line):
							return line
						case .conflict(let lines):
							let lines = lines.sorted()
							
							let dialogueOptions = lines
								.enumerated()
								.map {
									if configuration.useColor {
										"\(.cyan)\($0 + 1). \(.brightRed)'\($1)'\(.normal)"
									} else {
										"\($0 + 1). '\($1)'"
									}
								}
								.joined(separator: "\n")
							
							print("Conflicting dialogue:\n\(dialogueOptions)\nWhich would you like to pick?", terminator: " ")
							
							guard let choiceNumber = readLine().flatMap(Int.init),
								  let choice = lines[safely: choiceNumber - 1]
							else {
								print("Invalid response, please input a number matching one of the given options")
								if configuration.keepWindowOpen.isTrueOnError {
									waitForInput()
								}
								Self.exit(withError: nil)
							}
							
							return choice
					}
				}
				
				file = dexDialogueSaver(
					file,
					updatedDialogue: updatedDialogue,
					configuration: configuration
				)
			}
			
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
			
			if action == .unpack {
				logProgress(
					"Running post-processors",
					configuration: configuration
				)
				
				// TODO: make a new post-processing api that allows passing arguments? for things like dialogue labelling (and caching ripper results)
				for postProcessorName in configuration.experimental.postProcessors {
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
				}
				
				if configuration.experimental.dexDialogueLabeller {
					let dialogue = dmgRipper(processedFile)
					
//					struct Line: Codable {
//						var index: UInt32
//						var string: String
//					}
//
//					try JSONEncoder(.prettyPrinted)
//						.encode(dialogue.map(Line.init))
//						.write(to: URL(filePath: "/tmp/output.json")!)
					
					processedFile = dexDialogueLabeller(
						processedFile,
						dialogue: dialogue,
						configuration: configuration
					)
				}
				
				if configuration.experimental.dexBlockLabeller {
					processedFile = dexBlockLabeller(
						processedFile,
						configuration: configuration
					)
				}
				
				if configuration.experimental.dbsNameLabeller {
					let text = dtxRipper(processedFile)
					processedFile = dbsNameLabeller(
						processedFile,
						text: text,
						configuration: configuration
					)
				}
				
				if configuration.experimental.hmlNameLabeller {
					let text = dtxRipper(processedFile)
					processedFile = hmlNameLabeller(
						processedFile,
						text: text,
						configuration: configuration
					)
				}
				
				if configuration.experimental.mapLabeller {
					let text = dtxRipper(processedFile)
					processedFile = mapLabeller(
						processedFile,
						text: text,
						configuration: configuration
					)
				}
			}
			
#if !IN_CI
			print("\(.yellow)process", -processStart.timeIntervalSinceNow, "\(.normal)\(.clearToEndOfLine)")
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
#endif
			
			if configuration.overwriteOutput && savePath.exists() {
				try FileManager.default.removeItem(at: savePath)
				
#if !IN_CI
				print("\(.red)remove", -removeStart.timeIntervalSinceNow, "\(.normal)\(.clearToEndOfLine)")
#endif
			}
			
#if !IN_CI
			let writeStart = Date.now
#endif
			
			// TODO: remove overwriting argument, it already has the configuration
			try processedFile.write(
				into: outputFolder,
				overwriting: configuration.overwriteOutput,
				with: configuration
			)
			
#if !IN_CI
			print("\(.cyan)write", -writeStart.timeIntervalSinceNow, "\(.normal)\(.clearToEndOfLine)")
#endif
		}
	}
}
