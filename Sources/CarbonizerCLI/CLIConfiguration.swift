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
	
	var compression: Bool
	
	var hotReloading: Bool
	
	var processors: Processors
	
	struct Processors {
		var exportVivosaurModels: Bool
		var exportModels: Bool
		var exportSprites: Bool
		var exportImages: Bool
		var dexDialogueLabeller: Bool
		var dexDialogueSaver: Bool
		var dexBlockLabeller: Bool
		var battleFighterNameLabeller: Bool
		var ffcCreatureLabeller: Bool
		var maskNameLabeller: Bool
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
			
			// basically required for anything useful: MAR
			//
			// both ff1/ffc: _match, DCL, DEX, DMG, DMS, DTX, GRD, KIL, MPM, MMS, MPM 
			// ff1-only: 3BA, 3CL, BBG, BCO, CHR, DAL, DBA, DBS, DBT, DEP, DML, DSL, ECS, HML, KPS, MAP, MM3, RLS, SHP
			"fileTypes": ["_match", "3BA", "3CL", "BBG", "BCO", "CHR", "DAL", "DBA", "DBS", "DBT", "DCL", "DEP", "DEX", "DMG", "DML", "DMS", "DSL", "DTX", "ECS", "GRD", "HML", "KIL", "KPS", "MAP", "MAR", "MM3", "MMS", "MPM", "RLS", "SHP"],
			// "fileTypes": ["_match", "DCL", "DEX", "DMG", "DMS", "DTX", "GRD", "KIL", "MAR", "MMS", "MPM"], // ffc-compatible
			
			// limit the files carbonizer will unpack. any files included in this list will be skipped by carbonizer,
			// which will make carbonizer run faster and decrease the size of the any output ROMs. just make sure not
			// to accidentally skip a file you want to edit!
			//
			// these options accept globs within an nds' contents ("text/japanese", "episode/*", "model/**", "**/arc*")
			// file names in globs may contain one wildcard "arc*", but not two "*arc*"
			"onlyUnpack": [],
			"skipUnpacking": [],
			
			// not fully supported right now, requires externalMetadata to be enabled.
			// turning on compression will make the output ROM much smaller, but will
			// take a good amount of time to run. it's also good for creating patches,
			// so that the modded ROM matches the original as much as possible
			"compression": false,
			
			"hotReloading": false, // macOS only
			
			"processors": {
				// extract vivosaur 3D model files
				// required file types: MAR, 3CL
				"exportVivosaurModels": false,
				
				// extract non-vivosaur 3D model files
				// required file types: MAR, MM3
				"exportModels": false,
				
				// extract sprites (motion folder)    *temporarily broken, do not use*
				// required file types: MAR, MMS
				"exportSprites": false,
				
				// extract images (image folder)    *temporarily broken, do not use*
				// required file types: MAR, MPM
				"exportImages": false,
				
				// adds comments to DEX files that show the dialogue used in a given command
				// required file types: MAR, DEX, DMG
				"dexDialogueLabeller": false,
				
				// allows editing the comments made by dexDialogueLabeller, which will be
				// saved to the correct MSG file. new lines of dialogue cannot be added
				// required file types: MAR, DEX, DMG 
				"dexDialogueSaver": false,
				
				// labels the blocks of commands in DEX files with their block number. this number
				// is used by DEP files to control when a block triggers
				// required file types: MAR, DEX, DEP
				"dexBlockLabeller": false,
				
				// adds labels for the names of fighters in DBS files (battle folder)
				// required file types: MAR, DBS, DTX
				"battleFighterNameLabeller": false,
				
				// adds labels for the names of vivosaurs in creature_defs
				// required file types: MAR, DCL, DTX
				"ffcCreatureLabeller": false,
				
				// adds labels for the names of masks in `etc/headmask_defs`
				// required file types: MAR, HML, DTX
				"maskNameLabeller": false,
				
				// adds labels for the text in `etc/keyitem_defs`
				// required file types: MAR, KIL, DTX
				"keyItemLabeller": false,
				
				// adds labels for the names of maps in MAP files (`map/m/` folder)
				// required file types: MAR, MAP, DTX
				"mapLabeller": false,
				
				// adds labels for the descriptions in `etc/museum_defs`
				// required file types: MAR, DML, DTX
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
		case compressionMode, inputFiles, outputFolder, overwriteOutput, showProgress, keepWindowOpen, useColor, game, externalMetadata, fileTypes, onlyUnpack, skipUnpacking, compression, hotReloading, processors
	}
	
	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		// this is lazy to prevent infinite recursion
		lazy var fallback = Self.defaultConfiguration
		
		compressionMode =  try container.decodeIfPresent(CompressionMode.self, forKey: .compressionMode) ??
			fallback.compressionMode
		inputFiles =       try container.decodeIfPresent([String].self,        forKey: .inputFiles) ??
			fallback.inputFiles
		// since outputFolder is nil, having a fallback crashes
		outputFolder =     try container.decodeIfPresent(String.self,          forKey: .outputFolder)
		overwriteOutput =  try container.decodeIfPresent(Bool.self,            forKey: .overwriteOutput) ??
			fallback.overwriteOutput
		showProgress =     try container.decodeIfPresent(Bool.self,            forKey: .showProgress) ??
			fallback.showProgress
		keepWindowOpen =   try container.decodeIfPresent(KeepWindowOpen.self,  forKey: .keepWindowOpen) ??
			fallback.keepWindowOpen
		useColor =         try container.decodeIfPresent(Bool.self,            forKey: .useColor) ??
			fallback.useColor
		game =             try container.decodeIfPresent(Game.self,            forKey: .game) ??
			fallback.game
		externalMetadata = try container.decodeIfPresent(Bool.self,            forKey: .externalMetadata) ??
			fallback.externalMetadata
		fileTypes =        try container.decodeIfPresent(Set<String>.self,     forKey: .fileTypes) ??
			fallback.fileTypes
		onlyUnpack =       try container.decodeIfPresent([Glob].self,          forKey: .onlyUnpack) ??
			fallback.onlyUnpack
		skipUnpacking =    try container.decodeIfPresent([Glob].self,          forKey: .skipUnpacking) ??
			fallback.skipUnpacking
		compression =      try container.decodeIfPresent(Bool.self,            forKey: .compression) ??
			fallback.compression
		hotReloading =     try container.decodeIfPresent(Bool.self,            forKey: .hotReloading) ??
			fallback.hotReloading
		processors =       try container.decodeIfPresent(Processors.self,      forKey: .processors) ??
			fallback.processors
	}
}

struct UnknownOptions: Error, CustomStringConvertible {
	var options: Set<String>
	
	var description: String {
		if options.count == 1 {
			return "unknown configuration option: \(.red)\(options.first!)\(.normal)"
		} else {
			let optionList = options
				.sorted()
				.map { "\(.red)\($0)\(.normal)" }
				.joined(separator: ", ")
			
			return "unknown configuration options: \(optionList)"
		}
	}
}

extension CLIConfiguration.Processors: Decodable {
	enum CodingKeys: CodingKey, CaseIterable {
		case exportVivosaurModels, exportModels, exportSprites, exportImages, dexDialogueLabeller, dexDialogueSaver, dexBlockLabeller, battleFighterNameLabeller, ffcCreatureLabeller, maskNameLabeller, keyItemLabeller, mapLabeller, museumLabeller
	}
	
	init(from decoder: any Decoder) throws {
		let givenKeys = try [String: Bool](from: decoder).keys
		let allowedKeys = CodingKeys.allCases.map(\.stringValue)
		
		let extraKeys = Set(givenKeys).subtracting(Set(allowedKeys))
		guard extraKeys.isEmpty else {
			throw UnknownOptions(options: extraKeys)
		}
		
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		// this is lazy to prevent infinite recursion
		lazy var fallback = CLIConfiguration.defaultConfiguration.processors
		
		exportVivosaurModels =      try container.decodeIfPresent(Bool.self, forKey: .exportVivosaurModels) ??
			fallback.exportVivosaurModels
		exportModels =              try container.decodeIfPresent(Bool.self, forKey: .exportModels) ??
			fallback.exportModels
		exportSprites =             try container.decodeIfPresent(Bool.self, forKey: .exportSprites) ??
			fallback.exportSprites
		exportImages =              try container.decodeIfPresent(Bool.self, forKey: .exportImages) ??
			fallback.exportImages
		dexDialogueLabeller =       try container.decodeIfPresent(Bool.self, forKey: .dexDialogueLabeller) ??
			fallback.dexDialogueLabeller
		dexDialogueSaver =          try container.decodeIfPresent(Bool.self, forKey: .dexDialogueSaver) ??
			fallback.dexDialogueSaver
		dexBlockLabeller =          try container.decodeIfPresent(Bool.self, forKey: .dexBlockLabeller) ??
			fallback.dexBlockLabeller
		battleFighterNameLabeller = try container.decodeIfPresent(Bool.self, forKey: .battleFighterNameLabeller) ??
			fallback.battleFighterNameLabeller
		ffcCreatureLabeller =       try container.decodeIfPresent(Bool.self, forKey: .ffcCreatureLabeller) ??
			fallback.ffcCreatureLabeller
		maskNameLabeller =          try container.decodeIfPresent(Bool.self, forKey: .maskNameLabeller) ??
			fallback.maskNameLabeller
		keyItemLabeller =           try container.decodeIfPresent(Bool.self, forKey: .keyItemLabeller) ??
			fallback.keyItemLabeller
		mapLabeller =               try container.decodeIfPresent(Bool.self, forKey: .mapLabeller) ??
			fallback.mapLabeller
		museumLabeller =            try container.decodeIfPresent(Bool.self, forKey: .museumLabeller) ??
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
