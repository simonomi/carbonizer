public enum Processor: Hashable, Sendable {
	case tclFinder, mm3Finder, mmsFinder, mpmFinder, dexDialogueLabeller, dexDialogueSaver, dexBlockLabeller, dbsNameLabeller, hmlNameLabeller, keyItemLabeller, mapLabeller, museumLabeller
	
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
			case .hmlNameLabeller:     .unpack
			case .keyItemLabeller:     .unpack
			case .mapLabeller:         .unpack
			case .museumLabeller:      .unpack
		}
	}
	
	var stages: [Stage] {
		switch self {
			case .tclFinder:           [.tclFinder] // TODO: split into multiple stages
			case .mm3Finder:           [.mm3Finder] // TODO: split into multiple stages
			case .mmsFinder:           [.mmsFinder] // TODO: split into multiple stages
			case .mpmFinder:           [.mpmFinder] // TODO: split into multiple stages
			case .dexDialogueLabeller: [.dmgRipper, .dexDialogueLabeller]
			case .dexDialogueSaver:    [.dexDialogueRipper, .dexDialogueSaver]
			case .dexBlockLabeller:    [.dexBlockLabeller] // TODO: split into ripper
			case .dbsNameLabeller:     [.dtxRipper, .dbsNameLabeller]
			case .hmlNameLabeller:     [.dtxRipper, .hmlNameLabeller]
			case .keyItemLabeller:     [.dtxRipper, .keyItemLabeller]
			case .mapLabeller:         [.dtxRipper, .mapLabeller]
			case .museumLabeller:      [.dtxRipper, .museumLabeller]
		}
	}
	
	struct Environment {
		var text: [String]?
		var dialogue: [UInt32: String]?
	}
	
	enum Stage: Equatable {
		case dtxRipper, dmgRipper, dexDialogueRipper
		case dexDialogueLabeller, dexBlockLabeller, dbsNameLabeller, hmlNameLabeller, keyItemLabeller, mapLabeller, museumLabeller
		case dexDialogueSaver, tclFinder, mm3Finder, mmsFinder, mpmFinder
		
		func run(on file: inout any FileSystemObject, in environment: inout Environment) throws {
			switch self {
				case .dtxRipper:
					try file.runProcessor(dtxRipperF, on: "text/japanese", in: &environment, at: [])
				case .dmgRipper:
					try file.runProcessor(dmgRipperF, on: "msg/**", in: &environment, at: [])
//				case .dexDialogueRipper:
//					<#code#>
				case .dexDialogueLabeller:
					try file.runProcessor(dexDialogueLabellerF, on: "episode/**", in: &environment, at: [])
//				case .dexBlockLabeller:
//					<#code#>
//				case .dbsNameLabeller:
//					<#code#>
//				case .hmlNameLabeller:
//					<#code#>
//				case .keyItemLabeller:
//					<#code#>
//				case .mapLabeller:
//					<#code#>
//				case .museumLabeller:
//					<#code#>
//				case .dexDialogueSaver:
//					<#code#>
//				case .tclFinder:
//					<#code#>
//				case .mm3Finder:
//					<#code#>
//				case .mmsFinder:
//					<#code#>
//				case .mpmFinder:
//					<#code#>
				default: todo()
			}
		}
	}
}
