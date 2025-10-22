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
			case .ffcCreatureLabeller:       [.textRipper, .ffcCreatureLabeller]
			case .maskNameLabeller:          [.textRipper, .hmlNameLabeller]
			case .keyItemLabeller:           [.textRipper, .keyItemLabeller]
			case .mapLabeller:               [.textRipper, .mapLabeller]
			case .museumLabeller:            [.textRipper, .museumLabeller]
		}
	}
	
	var supportedGames: [Configuration.Game] {
		switch self {
			case .episodeDialogueLabeller:   [.ff1]
			case .episodeDialogueSaver:      [.ff1]
			case .exportVivosaurModels:      [.ff1]
			case .exportModels:              [.ff1] // TODO: ffc?
			case .exportSprites:             [.ff1] // TODO: ffc?
			case .exportImages:              [.ff1] // TODO: ffc?
			case .eventLabeller:             [.ff1]
			case .battleFighterNameLabeller: [.ff1]
			case .ffcCreatureLabeller:       [.ffc]
			case .maskNameLabeller:          [.ff1]
			case .keyItemLabeller:           [.ff1, .ffc]
			case .mapLabeller:               [.ff1]
			case .museumLabeller:            [.ff1]
		}
	}
	
	// MAR is dontWarn because it's already warned about elsewhere
	var requiredFileTypes: (warn: Set<String>, dontWarn: Set<String>) {
		switch self {
			case .episodeDialogueLabeller:   (warn: ["DMG"], dontWarn: ["MAR", "DEX"])
			case .episodeDialogueSaver:      (warn: ["DMG"], dontWarn: ["MAR", "DEX"])
			case .exportVivosaurModels:      (warn: ["3CL"], dontWarn: ["MAR"])
			case .exportModels:              (warn: ["MM3"], dontWarn: ["MAR"])
			case .exportSprites:             (warn: ["MMS"], dontWarn: ["MAR"])
			case .exportImages:              (warn: ["MPM"], dontWarn: ["MAR"])
			case .eventLabeller:             (warn: ["DEP"], dontWarn: ["MAR", "DEX"])
			case .battleFighterNameLabeller: (warn: ["DTX"], dontWarn: ["MAR", "DBS"])
			case .ffcCreatureLabeller:       (warn: ["DTX"], dontWarn: ["MAR", "DCL"])
			case .maskNameLabeller:          (warn: ["DTX"], dontWarn: ["MAR", "HML"])
			case .keyItemLabeller:           (warn: ["DTX"], dontWarn: ["MAR", "KIL"])
			case .mapLabeller:               (warn: ["DTX"], dontWarn: ["MAR", "MAP"])
			case .museumLabeller:            (warn: ["DTX"], dontWarn: ["MAR", "DML"])
		}
	}
	
	// a warning is only shown if every type *except* warn are enabled, to prevent
	// extra warnings when no file types are enabled
	func shouldRun(with configuration: Configuration) -> Bool {
		guard supportedGames.contains(configuration.game) else { return false }
		
		let (warn, dontWarn) = requiredFileTypes
		
		if !dontWarn.isSubset(of: configuration.fileTypes) {
			return false
		} else if !warn.isSubset(of: configuration.fileTypes) {
			let missingFileTypes = warn.subtracting(configuration.fileTypes)
			
			let fileTypeList = missingFileTypes
				.sorted()
				.map { "\(.red)\($0)\(.normal)" }
				.joined(separator: ", ")
			
			let isOrAre = if missingFileTypes.count == 1 {
				"is"
			} else {
				"are"
			}
			
			configuration.log(.warning, "the \(fileTypeList) file type\(sIfPlural(missingFileTypes.count)) \(isOrAre) not enabled, so \(.cyan)\(name)\(.normal) will not run")
			return false
		} else {
			return true
		}
	}
	
	enum Stage: Equatable {
		case dexDialogueRipper, dialogueRipper, textRipper, eventIDRipper, mm3Ripper, tclRipper, mpmRipper, mmsRipper
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
						on: "text/**",
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
