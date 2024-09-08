import ArgumentParser
import Foundation

struct CarbonizerConfiguration: Decodable {
	var compressionMode: CompressionMode
	var inputFiles: [URL]
	var overwriteOutput: Bool
	
	var fileTypes: [String]
	
	var skipExtracting: [String]
	var onlyExtract: [String]
	
	var experimental: ExperimentalOptions
	
	struct ExperimentalOptions: Decodable {
		var hotReloading: Bool
		var postProcessors: [String]
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
	}
	
	static let defaultConfiguration = Self(
		compressionMode: .auto,
		inputFiles: [],
		overwriteOutput: false,
		fileTypes: ["DEX", "DMG", "DMS", "DTX", "MAR", "MM3", "MPM", "NDS", "RLS"],
		skipExtracting: [],
		onlyExtract: [],
		experimental: ExperimentalOptions(
			hotReloading: false,
			postProcessors: []
		)
	)
	
	static let defaultConfigurationFormatted: String = """
		{
			"compressionMode": "auto", // pack, unpack, auto, ask
			"inputFiles": [],
			"overwriteOutput": false,
			
			// stable: DEX, DMG, DMS, DTX, MAR, MM3, MPM, NDS, RLS
			// experimental: AIS, AST, CHR, DAL, DCL, DNC, MFS, MMS, SHP
			"fileTypes": ["DEX", "DMG", "DMS", "DTX", "MAR", "MM3", "MPM", "NDS", "RLS"],
			
			"skipExtracting": [],
			"onlyExtract": [],

			"experimental": {
				"hotReloading": false, // macOS only
				
				// dexDialogueLabeller, dmgRipper, mm3Finder, mmsFinder, mpmFinder
				"postProcessors": []
			}
		}
		"""
}
