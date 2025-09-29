public enum Processor: String, Hashable, Sendable {
	// TODO: give these all nicer names
	case tclFinder, mm3Finder, mmsFinder, mpmFinder, dexDialogueLabeller, dexDialogueSaver, dexBlockLabeller, dbsNameLabeller, ffcCreatureLabeller, hmlNameLabeller, keyItemLabeller, mapLabeller, museumLabeller
	
	var name: String { rawValue }
	
	var shouldRunWhen: PackOrUnpack {
		switch self {
			case .tclFinder:           .unpack
			case .mm3Finder:           .unpack
			case .mmsFinder:           .unpack
			case .mpmFinder:           .unpack
			case .dexDialogueLabeller: .unpack
			case .dexDialogueSaver:    .pack
			case .dexBlockLabeller:    .unpack
			case .dbsNameLabeller:     .unpack
			case .ffcCreatureLabeller: .unpack
			case .hmlNameLabeller:     .unpack
			case .keyItemLabeller:     .unpack
			case .mapLabeller:         .unpack
			case .museumLabeller:      .unpack
		}
	}
	
	var stages: [Stage] {
		switch self {
			case .tclFinder:           [.tclRipper, .modelReparser, .textureExporter, .modelExporter]
			case .mm3Finder:           [.mm3Ripper, .modelReparser, .textureExporter, .modelExporter]
			case .mmsFinder:           todo() // TODO: everything
			case .mpmFinder:           todo() // TODO: everything
			case .dexDialogueLabeller: [.dmgRipper, .dexDialogueLabeller]
			case .dexDialogueSaver:    [.dexDialogueRipper, .dexDialogueSaver]
			case .dexBlockLabeller:    [.eventIDRipper, .dexBlockLabeller]
			case .dbsNameLabeller:     [.dtxRipper, .dbsNameLabeller]
			case .ffcCreatureLabeller: [.ffcTextRipper, .ffcCreatureLabeller]
			case .hmlNameLabeller:     [.dtxRipper, .hmlNameLabeller]
			case .keyItemLabeller:     [.dtxRipper, .keyItemLabeller]
			case .mapLabeller:         [.dtxRipper, .mapLabeller]
			case .museumLabeller:      [.dtxRipper, .museumLabeller]
		}
	}
	
	// TODO: define these on stages and just join them here ?
	var requiredFileTypes: [String] {
		switch self {
			case .tclFinder:           ["MAR", "3CL"]
			case .mm3Finder:           ["MAR", "MM3"]
			case .mmsFinder:           todo()
			case .mpmFinder:           todo()
			case .dexDialogueLabeller: ["MAR", "DMG", "DEX"]
			case .dexDialogueSaver:    ["MAR", "DEX", "DMG"]
			case .dexBlockLabeller:    ["MAR", "DEP", "DEX"]
			case .dbsNameLabeller:     ["MAR", "DTX", "DBS"]
			case .ffcCreatureLabeller: ["MAR", "DTX", "DCL"]
			case .hmlNameLabeller:     ["MAR", "DTX", "HML"]
			case .keyItemLabeller:     ["MAR", "DTX", "KIL"]
			case .mapLabeller:         ["MAR", "DTX", "MAP"]
			case .museumLabeller:      ["MAR", "DTX", "DML"]
		}
	}
	
	enum Stage: Equatable {
		case dexDialogueRipper, dmgRipper, dtxRipper, eventIDRipper, ffcTextRipper, mm3Ripper, tclRipper
		case dbsNameLabeller, dexBlockLabeller, dexDialogueLabeller, dexDialogueSaver, ffcCreatureLabeller, hmlNameLabeller, keyItemLabeller, mapLabeller, modelReparser, museumLabeller
		case modelExporter, textureExporter
		
		// TODO: instead of calling runProcessor, just return a ProcessorFunction?
		func run(
			on file: inout any FileSystemObject,
			in environment: inout Environment,
			configuration: Configuration
		) throws {
			switch self {
				case .dexDialogueRipper:
					try file.runProcessor(
						dexDialogueRipperF,
						on: "episode/e*",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .dmgRipper:
					try file.runProcessor(
						dmgRipperF,
						on: "msg/**",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .dtxRipper:
					try file.runProcessor(
						dtxRipperF,
						on: "text/japanese",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .eventIDRipper:
					try file.runProcessor(
						eventIDRipperF,
						on: "episode/**",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .ffcTextRipper:
					try file.runProcessor(
						ffcTextRipperF,
						on: "text/**",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .mm3Ripper:
					try file.runProcessor(
						mm3RipperF,
						on: "model/**",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .tclRipper:
					try file.runProcessor(
						tclRipperF,
						on: "model/battle/**",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .dbsNameLabeller:
					try file.runProcessor(
						dbsNameLabellerF,
						on: "battle/**",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .dexBlockLabeller:
					try file.runProcessor(
						dexBlockLabellerF,
						on: "episode/e*",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .dexDialogueLabeller:
					try file.runProcessor(
						dexDialogueLabellerF,
						on: "episode/e*",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .dexDialogueSaver:
					try file.runProcessor(
						dexDialogueSaverF,
						on: "episode/e*",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .ffcCreatureLabeller:
					try file.runProcessor(
						ffcCreatureLabellerF,
						on: "etc/creature_defs",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .hmlNameLabeller:
					try file.runProcessor(
						maskNameLabellerF,
						on: "etc/headmask_defs",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .keyItemLabeller:
					try file.runProcessor(
						keyItemLabellerF,
						on: "etc/keyitem_defs",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .mapLabeller:
					try file.runProcessor(
						mapLabellerF,
						on: "map/m/**",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .modelReparser:
					try file.runProcessor(
						modelReparserF,
						on: "model/**",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .museumLabeller:
					try file.runProcessor(
						museumLabellerF,
						on: "etc/museum_defs",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .modelExporter:
					try file.runProcessor(
						modelExporterF,
						on: "model/**",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .textureExporter:
					try file.runProcessor(
						textureExporterF,
						on: "model/**",
						in: &environment,
						at: [],
						configuration: configuration
					)
			}
		}
	}
}
