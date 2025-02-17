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
	
	var fileTypes: [String]
	
	// TODO: skip/only extract
//	var skipExtracting: [String]
//	var onlyExtract: [String]
	
	var experimental: ExperimentalOptions
	
	struct ExperimentalOptions {
		var hotReloading: Bool
		var postProcessors: [String]
		var dexDialogueLabeller: Bool
		var dexBlockLabeller: Bool
		var dbsNameLabeller: Bool
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
	
	static let defaultConfigurationString: String = """
		{
			"compressionMode": "auto", // pack, unpack, auto, ask
			"inputFiles": [],
			"outputFolder": null,
			"overwriteOutput": false,
			"showProgress": true,
			"keepWindowOpen": "onError", // always, never, onError
			"useColor": true,
			"dexCommandList": "ff1", // ff1, ffc, none
			
			// stable: DEP, DEX, DMG, DMS, DTX, MAR, MM3, MPM, NDS, RLS
			// experimental: 3CL, CHR, DBS, DCL, ECS, GRD, MAP, MFS, MMS
			"fileTypes": ["DEP", "DEX", "DMG", "DMS", "DTX", "MAR", "MM3", "MPM", "NDS", "RLS"],
			
			"experimental": {
				"hotReloading": false, // macOS only
				
				// 3clFinder, mm3Finder, mmsFinder, mpmFinder
				"postProcessors": [],
				
				"dexDialogueLabeller": false,
				"dexBlockLabeller": false,
				"dbsNameLabeller": false
			}
		}
		"""
#if os(Windows)
		.replacing("useColor\": true", with: "useColor\": false")
#endif
	
	static let defaultConfiguration = try! Self(decoding: defaultConfigurationString)
}

extension CarbonizerConfiguration: Decodable {
	enum CodingKeys: CodingKey {
		case compressionMode, inputFiles, outputFolder, overwriteOutput, showProgress, keepWindowOpen, useColor, dexCommandList, fileTypes, experimental
	}
	
	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		// this is lazy to prevent infinite recursion
		lazy var fallback = Self.defaultConfiguration
		
		compressionMode = try container.decodeIfPresent(CompressionMode.self,     forKey: .compressionMode) ??
			fallback.compressionMode
		inputFiles =      try container.decodeIfPresent([String].self,            forKey: .inputFiles) ??
			fallback.inputFiles
		outputFolder =    try container.decodeIfPresent(String.self,              forKey: .outputFolder) // no fallback because the default value is nil
		overwriteOutput = try container.decodeIfPresent(Bool.self,                forKey: .overwriteOutput) ??
			fallback.overwriteOutput
		showProgress =    try container.decodeIfPresent(Bool.self,                forKey: .showProgress) ??
			fallback.showProgress
		keepWindowOpen =  try container.decodeIfPresent(KeepWindowOpen.self,      forKey: .keepWindowOpen) ??
			fallback.keepWindowOpen
		useColor =        try container.decodeIfPresent(Bool.self,                forKey: .useColor) ??
			fallback.useColor
		dexCommandList =  try container.decodeIfPresent(DEXCommandList.self,      forKey: .dexCommandList) ??
			fallback.dexCommandList
		fileTypes =       try container.decodeIfPresent([String].self,            forKey: .fileTypes) ??
			fallback.fileTypes
		experimental =    try container.decodeIfPresent(ExperimentalOptions.self, forKey: .experimental) ??
			fallback.experimental
	}
}

extension CarbonizerConfiguration.ExperimentalOptions: Decodable {
	enum CodingKeys: CodingKey {
		case hotReloading, postProcessors, dexDialogueLabeller, dexBlockLabeller, dbsNameLabeller
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
		dexBlockLabeller =    try container.decodeIfPresent(Bool.self,     forKey: .dexBlockLabeller) ??
			fallback.dexBlockLabeller
		dbsNameLabeller =     try container.decodeIfPresent(Bool.self,     forKey: .dbsNameLabeller) ??
			fallback.dbsNameLabeller
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
