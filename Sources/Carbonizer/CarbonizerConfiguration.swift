import ArgumentParser
import Foundation

struct CarbonizerConfiguration {
	var compressionMode: CompressionMode
	var inputFiles: [String]
	var outputFolder: String?
	var overwriteOutput: Bool
	var showProgress: Bool
	var keepWindowOpen: KeepWindowOpen
	var useColor: Bool
	var dexCommandList: DEXCommandList
	var externalMetadata: Bool
	
	var fileTypes: Set<String>
	
	var onlyUnpack: [Glob]
	var skipUnpacking: [Glob]
	
	var experimental: ExperimentalOptions
	
	var cache: Cache
	
	struct ExperimentalOptions {
		var hotReloading: Bool
		var postProcessors: [String]
		var dexDialogueLabeller: Bool
		var dexDialogueSaver: Bool
		var dexBlockLabeller: Bool
		var dbsNameLabeller: Bool
		var hmlNameLabeller: Bool
		var mapLabeller: Bool
	}
	
	struct Cache {
		var fileExtensions: [(extension: String, type: any ProprietaryFileData.Type)]
		var magicBytes: [String: any ProprietaryFileData.Type]
		
		init(inputFileTypes: Set<String>) {
			let fileTypes: [any ProprietaryFileData.Type] = CarbonizerConfiguration.allFileTypes
				.filter { (fileTypeName, _) in
					inputFileTypes.contains(fileTypeName)
				}
				.flatMap { (_, fileType) in
					fileType.unpackedAndPacked()
				}
			
			fileExtensions = fileTypes
				.compactMap {
					if $0.fileExtension.isEmpty {
						nil
					} else {
						($0.fileExtension, $0)
					}
				}
			
			magicBytes = Dictionary(
				uniqueKeysWithValues: fileTypes
					.compactMap {
						if $0.magicBytes.isEmpty {
							nil
						} else {
							($0.magicBytes, $0)
						}
					}
			)
		}
	}
	
	enum CompressionMode: String, EnumerableFlag, Decodable {
		case pack, unpack, auto, ask
		
		static func name(for value: Self) -> NameSpecification {
			switch value {
				case .pack: .shortAndLong
				case .unpack: .shortAndLong
				case .auto: .long
				case .ask: .long
			}
		}
		
		enum PackOrUnpack { case pack, unpack }
		
		func action(packedStatus: PackedStatus) -> PackOrUnpack? {
			switch (self, packedStatus) {
				case (.pack, _), (.auto, .unpacked): 
					return .pack
				case (.unpack, _), (.auto, .packed):
					return .unpack
				default:
					print("Would you like to [p]ack or [u]npack? ")
					let answer = readLine()?.lowercased()
					
					if answer?.starts(with: "p") == true {
						return .pack
					} else if answer?.starts(with: "u") == true {
						return .unpack
					} else {
						return nil
					}
			}
		}
	}
	
	enum KeepWindowOpen: String, Decodable {
		case always, never, onError
		
		var isTrueOnError: Bool {
			self == .always || self == .onError
		}
	}
	
	enum DEXCommandList: String, Decodable {
		case ff1, ffc, none
	}
	
	fileprivate static var allFileTypes: [String: any ProprietaryFileData.Type] {[
		"3BA": TBA.Unpacked.self,
		"3CL": TCL.Unpacked.self,
		"BBG": BBG.Unpacked.self,
		"BCO": BCO.Unpacked.self,
		"CHR": CHR.Unpacked.self,
		"DAL": DAL.Unpacked.self,
		"DBS": DBS.Unpacked.self,
		"DCL": DCL.Unpacked.self,
		"DEP": DEP.Unpacked.self,
		"DEX": DEX.Unpacked.self,
		"DMG": DMG.Unpacked.self,
		"DML": DML.Unpacked.self,
		"DMS": DMS.Unpacked.self,
		"DSL": DSL.Unpacked.self,
		"DTX": DTX.Unpacked.self,
		"ECS": ECS.Unpacked.self,
		"GRD": GRD.Unpacked.self,
		"HML": HML.Unpacked.self,
		"KIL": KIL.Unpacked.self,
		"KPS": KPS.Unpacked.self,
		"MAP": MAP.Unpacked.self,
		"MFS": MFS.Unpacked.self,
		"MM3": MM3.Unpacked.self,
		"MMS": MMS.Unpacked.self,
		"MPM": MPM.Unpacked.self,
		"RLS": RLS.Unpacked.self,
		"SDAT": SDAT.Unpacked.self,
		"SHP": SHP.Unpacked.self,
	]}
	
	// TODO: including the file types makes updating carbonizer not use new file types :/
	// TODO: document how globs are weird bc they need to match the parent paths but have to deal with **/whatever patterns
	static let defaultConfigurationString: String = """
		{
			// auto 
			"compressionMode": "auto", // pack, unpack, auto, ask
			
			"inputFiles": [],
			
			// where any output files will be placed 
			"outputFolder": null,
			
			// whether to overwrite any already-existing output files
			"overwriteOutput": false,
			
			"showProgress": true,
			
			"keepWindowOpen": "onError", // always, never, onError
			
			// enables pretty colorful output! not all terminals support colors though :( 
			"useColor": true,
			
			// ff1 and ffc use different commands in their DEX files (episode folder), you should
			// pick the one that matches the game you're unpacking. setting this to none may
			// fix some weird bugs if something unexpected occurs (but it'll make episode files
			// less readable)
			"dexCommandList": "ff1", // ff1, ffc, none
			
			// stores metadata for MAR files in a separate file, rather than the creation
			// date. this can avoid some problems, but creates a bunch of annoying extra files.
			// required to make MAR packing work on linux
			"externalMetadata": false,
			
			// basically required for anything useful: NDS, MAR
			//
			// stable: _match, 3BA, 3CL, BBG, BCO, CHR, DAL, DBS, DCL, DEP, DEX, DMG, DMS, DSL, DTX, ECS, GRD, HML, KPS, MAP, MAR, MM3, MMS, MPM, NDS, RLS, SHP
			// experimental: DML, MFS, SDAT
			"fileTypes": ["_match", "3BA", "3CL", "BBG", "BCO", "CHR", "DAL", "DBS", "DCL", "DEP", "DEX", "DMG", "DMS", "DSL", "DTX", "ECS", "GRD", "HML", "KPS", "MAP", "MAR", "MM3", "MMS", "MPM", "NDS", "RLS", "SHP"],
			
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
				
				// adds labels for the names of maps in MAP files (`map/m/` folder)
				//
				// make sure to enable both the MAP and DTX file types or nothing will happen
				"mapLabeller": false
			}
		}
		"""
#if os(Windows)
		.replacing("useColor\": true", with: "useColor\": false")
#endif
	
	static let defaultConfiguration = try! Self(decoding: defaultConfigurationString)
	
	func shouldUnpack(_ path: [String]) -> Bool {
		if skipUnpacking.contains(where: { $0.matches(path) }) {
			false
		} else if onlyUnpack.isNotEmpty {
			onlyUnpack.contains { $0.matches(path) }
		} else {
			true
		}
	}
}

extension CarbonizerConfiguration: Decodable {
	enum CodingKeys: CodingKey {
		case compressionMode, inputFiles, outputFolder, overwriteOutput, showProgress, keepWindowOpen, useColor, dexCommandList, externalMetadata, fileTypes, onlyUnpack, skipUnpacking, experimental
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
		dexCommandList =   try container.decodeIfPresent(DEXCommandList.self,      forKey: .dexCommandList) ??
			fallback.dexCommandList
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
		
		cache = Cache(inputFileTypes: fileTypes)
		
		// TODO: error on unknown file type
	}
}

extension CarbonizerConfiguration.ExperimentalOptions: Decodable {
	enum CodingKeys: CodingKey {
		case hotReloading, postProcessors, dexDialogueLabeller, dexDialogueSaver, dexBlockLabeller, dbsNameLabeller, hmlNameLabeller, mapLabeller
	}
	
	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		// this is lazy to prevent infinite recursion
		lazy var fallback = CarbonizerConfiguration.defaultConfiguration.experimental
		
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
		mapLabeller =         try container.decodeIfPresent(Bool.self,     forKey: .mapLabeller) ??
			fallback.mapLabeller
	}
}

extension CarbonizerConfiguration {
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

extension CarbonizerConfiguration {
	func fileType(name: String) -> (any ProprietaryFileData.Type)? {
		cache.fileExtensions
			.first { name.hasSuffix($0.extension) }?
			.type
	}
	
	func fileType(magicBytes: String) -> (any ProprietaryFileData.Type)? {
		cache.magicBytes[magicBytes]
	}
}

fileprivate extension ProprietaryFileData {
	static func unpackedAndPacked() -> [any ProprietaryFileData.Type] {
		[Unpacked.self, Packed.self]
	}
}
