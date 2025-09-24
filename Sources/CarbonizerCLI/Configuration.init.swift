import Carbonizer

extension Configuration {
	init(
		_ cliConfiguration: CLIConfiguration,
		logHandler: (@Sendable (String) -> Void)?
	) throws {
		
		try self.init(
			overwriteOutput: cliConfiguration.overwriteOutput,
			game: .init(cliConfiguration.game),
			externalMetadata: cliConfiguration.externalMetadata,
			fileTypes: cliConfiguration.fileTypes,
			onlyUnpack: cliConfiguration.onlyUnpack,
			skipUnpacking: cliConfiguration.skipUnpacking,
			processors: .init(cliConfiguration.experimental),
			logHandler: logHandler
		)
	}
}

extension Configuration.Game {
	init(_ cli: CLIConfiguration.Game) {
		self = switch cli {
			case .ff1: .ff1
			case .ffc: .ffc
		}
	}
}

extension Set<Processor> {
	init(_ cli: CLIConfiguration.ExperimentalOptions) {
		var result: Set<Processor> = []
		
		for postProcessor in cli.postProcessors {
			let newProcessor: Processor = switch postProcessor {
				case "3clFinder": .tclFinder
				case "mm3Finder": .mm3Finder
				case "mmsFinder": .mmsFinder
				case "mpmFinder": .mpmFinder
				default:
					fatalError("TODO: throw")
			}
			
			result.insert(newProcessor)
		}
		
		if cli.dexDialogueLabeller {
			result.insert(.dexDialogueLabeller)
		}
		
		if cli.dexDialogueSaver {
			result.insert(.dexDialogueSaver)
		}
		
		if cli.dexBlockLabeller {
			result.insert(.dexBlockLabeller)
		}
		
		if cli.dbsNameLabeller {
			result.insert(.dbsNameLabeller)
		}
		
		if cli.hmlNameLabeller {
			result.insert(.hmlNameLabeller)
		}
		
		if cli.keyItemLabeller {
			result.insert(.keyItemLabeller)
		}
		
		if cli.mapLabeller {
			result.insert(.mapLabeller)
		}
		
		if cli.museumLabeller {
			result.insert(.museumLabeller)
		}
		
		self = result
	}
}
