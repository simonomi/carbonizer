import ANSICodes
import Foundation

// TODO: list
// - add a `carbonizer version.json` file or smthn to contain the version number
//   - if trying to pack from too old a version (semver or smthn), give an error
//   - also the list of file types, so if some file types were extracted they need to be repacked
// - make reading (and writing?) use way fewer filesystem calls
//   - enumerator

public enum Carbonizer {
	public static func auto(
		_ filePath: URL,
		into outputFolder: URL,
		configuration: Configuration
	) throws {
		try run(.auto, path: filePath, into: outputFolder, configuration: configuration)
	}
	
	public static func pack(
		_ filePath: URL,
		into outputFolder: URL,
		configuration: Configuration
	) throws {
		try run(.pack, path: filePath, into: outputFolder, configuration: configuration)
	}
	
	public static func unpack(
		_ filePath: URL,
		into outputFolder: URL,
		configuration: Configuration
	) throws {
		try run(.unpack, path: filePath, into: outputFolder, configuration: configuration)
	}
	
//			if configuration.experimental.dexDialogueSaver, action == .pack {
//				let updatedDialogueWithConflicts = try dexDialogueRipper(file)
//				
//				let updatedDialogue = updatedDialogueWithConflicts.mapValues {
//					switch $0 {
//						case .one(let line):
//							return line
//						case .conflict(let lines):
//							let lines = lines.sorted()
//							
//							let dialogueOptions = lines
//								.enumerated()
//								.map {
//									if configuration.useColor {
//										"\(.cyan)\($0 + 1). \(.brightRed)'\($1)'\(.normal)"
//									} else {
//										"\($0 + 1). '\($1)'"
//									}
//								}
//								.joined(separator: "\n")
//							
//							print("Conflicting dialogue:\n\(dialogueOptions)\nWhich would you like to pick?", terminator: " ")
//							
//							guard let choiceNumber = readLine().flatMap(Int.init),
//								  let choice = lines[safely: choiceNumber - 1]
//							else {
//								print("Invalid response, please input a number matching one of the given options")
//								if configuration.keepWindowOpen.isTrueOnError {
//									waitForInput()
//								}
//								Self.exit(withError: nil)
//							}
//							
//							return choice
//					}
//				}
//				
//				file = dexDialogueSaver(
//					file,
//					updatedDialogue: updatedDialogue,
//					configuration: configuration
//				)
//			}
//			
//			var processedFile: any FileSystemObject
//			switch action {
//				case .pack:
//					processedFile = file.packed(configuration: configuration)
//				case .unpack:
//					processedFile = try file.unpacked(path: [], configuration: configuration)
//				case nil:
//					print("Skipping file...")
//					continue
//			}
//			
//			if action == .unpack {
//				configuration.log("Running post-processors")
//				
//				// TODO: make a new post-processing api that allows passing arguments? for things like dialogue labelling (and caching ripper results)
//				// some kind of 'environment' that can be read/written to?
//				for postProcessorName in configuration.experimental.postProcessors {
//					switch postProcessorName {
//						case "3clFinder":
//							processedFile = try processedFile.postProcessed(with: tclFinder)
//						case "mm3Finder":
//							processedFile = try processedFile.postProcessed(with: mm3Finder)
//						case "mmsFinder":
//							processedFile = try processedFile.postProcessed(with: mmsFinder)
//						case "mpmFinder":
//							processedFile = try processedFile.postProcessed(with: mpmFinder)
//						default:
//							print("Could not find a post-processor named '\(postProcessorName)', skipping...")
//							continue
//					}
//				}
//				
//				if configuration.experimental.dexDialogueLabeller {
//					let dialogue = dmgRipper(processedFile)
//					
////					struct Line: Codable {
////						var index: UInt32
////						var string: String
////					}
////
////					try JSONEncoder(.prettyPrinted)
////						.encode(dialogue.map(Line.init))
////						.write(to: URL(filePath: "/tmp/output.json")!)
//					
//					processedFile = dexDialogueLabeller(
//						processedFile,
//						dialogue: dialogue,
//						configuration: configuration
//					)
//				}
//				
//				if configuration.experimental.dexBlockLabeller {
//					processedFile = dexBlockLabeller(
//						processedFile,
//						configuration: configuration
//					)
//				}
//				
//				if configuration.experimental.dbsNameLabeller {
//					let text = try dtxRipper(processedFile)
//					processedFile = dbsNameLabeller(
//						processedFile,
//						text: text,
//						configuration: configuration
//					)
//				}
//				
//				if configuration.experimental.hmlNameLabeller {
//					let text = try dtxRipper(processedFile)
//					processedFile = hmlNameLabeller(
//						processedFile,
//						text: text,
//						configuration: configuration
//					)
//				}
//				
//				if configuration.experimental.keyItemLabeller {
//					let text = try dtxRipper(processedFile)
//					processedFile = keyItemLabeller(
//						processedFile,
//						text: text,
//						configuration: configuration
//					)
//				}
//				
//				if configuration.experimental.mapLabeller {
//					let text = try dtxRipper(processedFile)
//					processedFile = mapLabeller(
//						processedFile,
//						text: text,
//						configuration: configuration
//					)
//				}
//				
//				if configuration.experimental.museumLabeller {
//					let text = try dtxRipper(processedFile)
//					processedFile = museumLabeller(
//						processedFile,
//						text: text,
//						configuration: configuration
//					)
//				}
//			}
}
