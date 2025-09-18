import Carbonizer

extension Carbonizer.Configuration {
	init(
		_ cliConfiguration: CarbonizerCLI.Configuration,
		logHandler: (@Sendable (String) -> Void)?
	) {
		
		self.init(
			overwriteOutput: cliConfiguration.overwriteOutput,
			dexCommandList: .init(cliConfiguration.dexCommandList),
			externalMetadata: cliConfiguration.externalMetadata,
			fileTypes: cliConfiguration.fileTypes,
			onlyUnpack: cliConfiguration.onlyUnpack,
			skipUnpacking: cliConfiguration.skipUnpacking,
			experimental: .init(cliConfiguration.experimental),
			logHandler: logHandler
		)
	}
}

extension Carbonizer.Configuration.DEXCommandList {
	init(_ cli: CarbonizerCLI.Configuration.DEXCommandList) {
		self = switch cli {
			case .ff1: .ff1
			case .ffc: .ffc
			case .none: .none
		}
	}
}

extension Carbonizer.Configuration.ExperimentalOptions {
	init(_ cli: CarbonizerCLI.Configuration.ExperimentalOptions) {
		self.init(
			postProcessors: cli.postProcessors,
			dexDialogueLabeller: cli.dexDialogueLabeller,
			dexDialogueSaver: cli.dexDialogueSaver,
			dexBlockLabeller: cli.dexBlockLabeller,
			dbsNameLabeller: cli.dbsNameLabeller,
			hmlNameLabeller: cli.hmlNameLabeller,
			keyItemLabeller: cli.keyItemLabeller,
			mapLabeller: cli.mapLabeller,
			museumLabeller: cli.museumLabeller
		)
	}
}
