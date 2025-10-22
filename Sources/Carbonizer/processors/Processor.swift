public enum Processor: String, Hashable, Sendable {
	case episodeDialogueLabeller, episodeDialogueSaver, exportVivosaurModels, exportModels, exportSprites, exportImages, eventLabeller, battleFighterNameLabeller, ffcCreatureLabeller, maskNameLabeller, keyItemLabeller, mapLabeller, museumLabeller
	
	var name: String { rawValue }
	
	var shouldRunWhen: PackOrUnpack {
		switch self {
			case .episodeDialogueLabeller:   .unpack
			case .episodeDialogueSaver:      .pack
			case .exportVivosaurModels:      .unpack
			case .exportModels:              .unpack
			case .exportSprites:             .unpack
			case .exportImages:              .unpack
			case .eventLabeller:             .unpack
			case .battleFighterNameLabeller: .unpack
			case .ffcCreatureLabeller:       .unpack
			case .maskNameLabeller:          .unpack
			case .keyItemLabeller:           .unpack
			case .mapLabeller:               .unpack
			case .museumLabeller:            .unpack
		}
	}
	
	var stages: [Stage] {
		switch self {
			case .episodeDialogueLabeller:   [.dialogueRipper, .dexDialogueLabeller]
			case .episodeDialogueSaver:      [.dexDialogueRipper, .dexDialogueSaver]
			case .exportVivosaurModels:      [.tclRipper, .modelReparser, .textureExporter, .modelExporter]
			case .exportModels:              [.mm3Ripper, .modelReparser, .textureExporter, .modelExporter]
			case .exportSprites:             [.mmsRipper, .spriteReparser, .spriteExporter]
			case .exportImages:              [.mpmRipper, .imageReparser, .imageExporter]
			case .eventLabeller:             [.eventIDRipper, .eventLabeller]
			case .battleFighterNameLabeller: [.textRipper, .dbsNameLabeller]
			case .ffcCreatureLabeller:       [.ffcTextRipper, .ffcCreatureLabeller]
			case .maskNameLabeller:          [.textRipper, .hmlNameLabeller]
			case .keyItemLabeller:           [.textRipper, .keyItemLabeller]
			case .mapLabeller:               [.textRipper, .mapLabeller]
			case .museumLabeller:            [.textRipper, .museumLabeller]
		}
	}
	
	var requiredFileTypes: [String] {
		switch self {
			case .episodeDialogueLabeller:   ["MAR", "DMG", "DEX"]
			case .episodeDialogueSaver:      ["MAR", "DEX", "DMG"]
			case .exportVivosaurModels:      ["MAR", "3CL"]
			case .exportModels:              ["MAR", "MM3"]
			case .exportSprites:             ["MAR", "MMS"]
			case .exportImages:              ["MAR", "MPM"]
			case .eventLabeller:             ["MAR", "DEP", "DEX"]
			case .battleFighterNameLabeller: ["MAR", "DTX", "DBS"]
			case .ffcCreatureLabeller:       ["MAR", "DTX", "DCL"]
			case .maskNameLabeller:          ["MAR", "DTX", "HML"]
			case .keyItemLabeller:           ["MAR", "DTX", "KIL"]
			case .mapLabeller:               ["MAR", "DTX", "MAP"]
			case .museumLabeller:            ["MAR", "DTX", "DML"]
		}
	}
	
	// TODO: required game
	
	enum Stage: Equatable {
		case dexDialogueRipper, dialogueRipper, textRipper, eventIDRipper, ffcTextRipper, mm3Ripper, tclRipper, mpmRipper, mmsRipper
		case dbsNameLabeller, dexDialogueLabeller, dexDialogueSaver, eventLabeller, ffcCreatureLabeller, hmlNameLabeller, keyItemLabeller, mapLabeller, museumLabeller
		case imageReparser, modelReparser, spriteReparser
		case imageExporter, modelExporter, spriteExporter, textureExporter
		
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
				case .dialogueRipper:
					try file.runProcessor(
						dialogueRipperF,
						on: "msg/**",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .textRipper:
					try file.runProcessor(
						textRipperF,
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
				case .mpmRipper:
					try file.runProcessor(
						mpmRipperF,
						on: "image/**",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .mmsRipper:
					try file.runProcessor(
						mmsRipperF,
						on: "motion/**",
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
				case .eventLabeller:
					try file.runProcessor(
						dexEventLabellerF,
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
				case .museumLabeller:
					try file.runProcessor(
						museumLabellerF,
						on: "etc/museum_defs",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .imageReparser:
					try file.runProcessor(
						imageReparserF,
						on: "image/**",
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
				case .spriteReparser:
					try file.runProcessor(
						spriteReparserF,
						on: "motion/**",
						in: &environment,
						at: [],
						configuration: configuration
					)
				case .imageExporter:
					try file.runProcessor(
						imageExporterF,
						on: "image/**",
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
				case .spriteExporter:
					try file.runProcessor(
						spriteExporterF,
						on: "motion/**",
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
