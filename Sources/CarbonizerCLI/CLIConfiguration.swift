import Carbonizer
import Foundation
import ArgumentParser

struct CLIConfiguration : Sendable {
	var compressionMode: CompressionMode
	var inputFiles: [String]
	var outputFolder: String?
	var overwriteOutput: Bool
	var showProgress: Bool
	var keepWindowOpen: KeepWindowOpen
	var useColor: Bool // TODO: use environment variable (COLORTERM is nil on windows tho)
	var game: Game
	var externalMetadata: Bool
	
	var fileTypes: Set<String>
	
	var onlyUnpack: [Glob]
	var skipUnpacking: [Glob]
	
	var experimental: ExperimentalOptions
	
	// TODO: rename processors, split into 'processors' section, make hotreloading stable
	struct ExperimentalOptions {
		var hotReloading: Bool
		var postProcessors: [String]
		var dexDialogueLabeller: Bool
		var dexDialogueSaver: Bool
		var dexBlockLabeller: Bool
		var dbsNameLabeller: Bool
		var hmlNameLabeller: Bool
		var keyItemLabeller: Bool
		var mapLabeller: Bool
		var museumLabeller: Bool
	}
	
	enum CompressionMode: String, EnumerableFlag, Decodable {
		case pack, unpack, auto
		
		static func name(for value: Self) -> NameSpecification {
			switch value {
				case .pack: .shortAndLong
				case .unpack: .shortAndLong
				case .auto: .long
			}
		}
	}
	
	enum KeepWindowOpen: String, Decodable {
		case always, never, onError
		
		var isTrueOnError: Bool {
			self == .always || self == .onError
		}
	}
	
	enum Game: String, Decodable {
		case ff1, ffc
	}
	
	// TODO: document how globs are weird bc they need to match the parent paths but have to deal with **/whatever patterns?
	static let defaultConfigurationString: String = """
		{
			"compressionMode": "auto", // auto, pack, unpack
			
			"inputFiles": [],
			
			// where any output files will be placed
			"outputFolder": null,
			
			// whether to overwrite any already-existing output files
			"overwriteOutput": false,
			
			"showProgress": true,
			
			"keepWindowOpen": "onError", // always, never, onError
			
			// enables pretty colorful output! not all terminals support colors though :(
			"useColor": true,
			
			// stores metadata for MAR files in a separate file, rather than the creation
			// date. this can avoid some problems, but creates a bunch of annoying extra files.
			// required to make MAR packing work on linux
			"externalMetadata": false,
			
			// ff1 and ffc have different formats for the "same" files (DEX, DCL, etc),
			// so you need to select which game is being run on
			"game": "ff1", // ff1, ffc
			
			// basically required for anything useful: NDS, MAR
			//
			// both ff1/ffc: _match, DCL, DEX, DMG, DMS, DTX, GRD, KIL, MPM, MMS, MPM 
			// ff1-only: 3BA, 3CL, BBG, BCO, CHR, DAL, DBA, DBS, DBT, DEP, DML, DSL, ECS, HML, KPS, MAP, MM3, RLS, SHP
			"fileTypes": ["_match", "3BA", "3CL", "BBG", "BCO", "CHR", "DAL", "DBA", "DBS", "DBT", "DCL", "DEP", "DEX", "DMG", "DML", "DMS", "DSL", "DTX", "ECS", "GRD", "HML", "KIL", "KPS", "MAP", "MAR", "MM3", "MMS", "MPM", "NDS", "RLS", "SHP"],
			// "fileTypes": ["_match", "DCL", "DEX", "DMG", "DMS", "DTX", "GRD", "KIL", "MAR", "MPM", "MMS", "MPM", "NDS"], // ffc-compatible
			
			// limit the files carbonizer will unpack. any files included in this list will be skipped by carbonizer,
			// which will make carbonizer run faster and decrease the size of the any output ROMs. just make sure not
			// to accidentally skip a file you want to edit!
			//
			// these options accept globs within an nds' contents ("text/japanese", "episode/*", "model/**", "**/arc*")
			// file names in globs may contain one wildcard "arc*", but not two "*arc*"
			"onlyUnpack": [],
			"skipUnpacking": [],
			
			"experimental": {
				"hotReloading": false, // macOS only
				
				// 3clFinder: extract vivosaur 3D model files
				//            make sure to enable the 3CL file type or nothing will happen
				// mm3Finder: extract non-vivosaur 3D model files
				//            make sure to enable the MM3 file type or nothing will happen
				// mmsFinder: extract sprites (motion folder)
				//            make sure to enable the MMS file type or nothing will happen
				// mpmFinder: extract images (image folder)
				//            make sure to enablethe  MPM file type or nothing will happen
				"postProcessors": [],
				
				// adds comments to DEX files that show the dialogue used in a given command
				//
				// make sure to enable the DEX and DMG file types or nothing will happen
				"dexDialogueLabeller": false,
				
				// allows editing the comments made by dexDialogueLabeller, which will be
				// saved to the correct MSG file. new lines of dialogue cannot be added
				//
				// make sure to enable the DEX and DMG file types or nothing will happen 
				"dexDialogueSaver": false,
				
				// labels the blocks of commands in DEX files with their block number. this number
				// is used by DEP files to control when a block triggers
				//
				// make sure to enable both the DEX and DEP file types or nothing will happen
				"dexBlockLabeller": false,
				
				// adds labels for the names of fighters in DBS files (battle folder)
				//
				// make sure to enable both the DBS and DTX file types or nothing will happen
				"dbsNameLabeller": false,
				
				// adds labels for the names of masks in `etc/headmask_defs`
				//
				// make sure to enable both the HML and DTX file types or nothing will happen
				"hmlNameLabeller": false,
				
				// adds labels for the text in `etc/keyitem_defs`
				//
				// make sure to enable both the KIL and DTX file types or nothing will happen
				"keyItemLabeller": false,
				
				// adds labels for the names of maps in MAP files (`map/m/` folder)
				//
				// make sure to enable both the MAP and DTX file types or nothing will happen
				"mapLabeller": false,
				
				// adds labels for the descriptions in `etc/museum_defs`
				//
				// make sure to enable both the DML and DTX file types or nothing will happen
				"museumLabeller": false
			}
		}
		"""
#if os(Windows)
		.replacing("useColor\": true", with: "useColor\": false")
#endif
	
	static let defaultConfiguration = try! Self(decoding: defaultConfigurationString)
}
	
extension CLIConfiguration: Decodable {
	enum CodingKeys: CodingKey {
		case compressionMode, inputFiles, outputFolder, overwriteOutput, showProgress, keepWindowOpen, useColor, game, externalMetadata, fileTypes, onlyUnpack, skipUnpacking, experimental
	}
	
	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		// this is lazy to prevent infinite recursion
		lazy var fallback = Self.defaultConfiguration
		
		compressionMode =  try container.decodeIfPresent(CompressionMode.self,     forKey: .compressionMode) ??
		fallback.compressionMode
		inputFiles =       try container.decodeIfPresent([String].self,            forKey: .inputFiles) ??
		fallback.inputFiles
		outputFolder =     try container.decodeIfPresent(String.self,              forKey: .outputFolder) ??
		nil
		overwriteOutput =  try container.decodeIfPresent(Bool.self,                forKey: .overwriteOutput) ??
		fallback.overwriteOutput
		showProgress =     try container.decodeIfPresent(Bool.self,                forKey: .showProgress) ??
		fallback.showProgress
		keepWindowOpen =   try container.decodeIfPresent(KeepWindowOpen.self,      forKey: .keepWindowOpen) ??
		fallback.keepWindowOpen
		useColor =         try container.decodeIfPresent(Bool.self,                forKey: .useColor) ??
		fallback.useColor
		game =             try container.decodeIfPresent(Game.self,                forKey: .game) ??
		fallback.game
		externalMetadata = try container.decodeIfPresent(Bool.self,                forKey: .externalMetadata) ??
		fallback.externalMetadata
		fileTypes =        try container.decodeIfPresent(Set<String>.self,         forKey: .fileTypes) ??
		fallback.fileTypes
		onlyUnpack =       try container.decodeIfPresent([Glob].self,              forKey: .onlyUnpack) ??
		fallback.onlyUnpack
		skipUnpacking =    try container.decodeIfPresent([Glob].self,              forKey: .skipUnpacking) ??
		fallback.skipUnpacking
		experimental =     try container.decodeIfPresent(ExperimentalOptions.self, forKey: .experimental) ??
		fallback.experimental
	}
}

extension CLIConfiguration.ExperimentalOptions: Decodable {
	enum CodingKeys: CodingKey {
		case hotReloading, postProcessors, dexDialogueLabeller, dexDialogueSaver, dexBlockLabeller, dbsNameLabeller, hmlNameLabeller, keyItemLabeller, mapLabeller, museumLabeller
	}
	
	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		// this is lazy to prevent infinite recursion
		lazy var fallback = CLIConfiguration.defaultConfiguration.experimental
		
		hotReloading =        try container.decodeIfPresent(Bool.self,     forKey: .hotReloading) ??
		fallback.hotReloading
		postProcessors =      try container.decodeIfPresent([String].self, forKey: .postProcessors) ??
		fallback.postProcessors
		dexDialogueLabeller = try container.decodeIfPresent(Bool.self,     forKey: .dexDialogueLabeller) ??
		fallback.dexDialogueLabeller
		dexDialogueSaver =    try container.decodeIfPresent(Bool.self,     forKey: .dexDialogueSaver) ??
		fallback.dexDialogueSaver
		dexBlockLabeller =    try container.decodeIfPresent(Bool.self,     forKey: .dexBlockLabeller) ??
		fallback.dexBlockLabeller
		dbsNameLabeller =     try container.decodeIfPresent(Bool.self,     forKey: .dbsNameLabeller) ??
		fallback.dbsNameLabeller
		hmlNameLabeller =     try container.decodeIfPresent(Bool.self,     forKey: .hmlNameLabeller) ??
		fallback.hmlNameLabeller
		keyItemLabeller =     try container.decodeIfPresent(Bool.self,     forKey: .keyItemLabeller) ??
		fallback.keyItemLabeller
		mapLabeller =         try container.decodeIfPresent(Bool.self,     forKey: .mapLabeller) ??
		fallback.mapLabeller
		museumLabeller =      try container.decodeIfPresent(Bool.self,     forKey: .museumLabeller) ??
		fallback.museumLabeller
	}
}

extension CLIConfiguration {
	init(contentsOf path: URL) throws {
		let text: String
		if path.exists() {
			text = try String(contentsOf: path, encoding: .utf8)
		} else {
			text = Self.defaultConfigurationString
			try text.write(to: path, atomically: true, encoding: .utf8)
		}
		
		self = try Self(decoding: text)
	}
	
	init(decoding text: String) throws {
		let data = text.data(using: .utf8)!
		
		let decoder = JSONDecoder()
		decoder.allowsJSON5 = true
		
		self = try decoder.decode(Self.self, from: data)
	}
}
