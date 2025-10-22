import Carbonizer

extension Configuration {
	init(
		_ cliConfiguration: CLIConfiguration,
		logHandler: (@Sendable (Configuration.Log) -> Void)?
	) throws {
		try self.init(
			overwriteOutput: cliConfiguration.overwriteOutput,
			game: .init(cliConfiguration.game),
			externalMetadata: cliConfiguration.externalMetadata,
			fileTypes: cliConfiguration.fileTypes,
			onlyUnpack: cliConfiguration.onlyUnpack,
			skipUnpacking: cliConfiguration.skipUnpacking,
			compression: cliConfiguration.compression,
			processors: .init(cliConfiguration.processors),
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
	init(_ cli: CLIConfiguration.Processors) {
		var result: Set<Processor> = []
		
		// TODO: ff1/ffc processors
		if cli.exportVivosaurModels {
			result.insert(.exportVivosaurModels)
		}
		
		if cli.exportModels {
			result.insert(.exportModels)
		}
		
		if cli.exportSprites {
			result.insert(.exportSprites)
		}
		
		if cli.exportImages {
			result.insert(.exportImages)
		}
		
		if cli.episodeDialogueLabeller {
			result.insert(.episodeDialogueLabeller)
		}
		
		if cli.episodeDialogueSaver {
			result.insert(.episodeDialogueSaver)
		}
		
		if cli.eventLabeller {
			result.insert(.eventLabeller)
		}
		
		if cli.battleFighterNameLabeller {
			result.insert(.battleFighterNameLabeller)
		}
		
		if cli.ffcCreatureLabeller {
			result.insert(.ffcCreatureLabeller)
		}
		
		if cli.maskNameLabeller {
			result.insert(.maskNameLabeller)
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
