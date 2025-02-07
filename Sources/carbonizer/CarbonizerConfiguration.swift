import ArgumentParser
import Foundation

struct CarbonizerConfiguration: Decodable {
	var compressionMode: CompressionMode = .auto
	var inputFiles: [String] = []
	var outputFolder: String? = nil
	var overwriteOutput: Bool = false
	var showProgress: Bool = true
	var keepWindowOpen: KeepWindowOpen = .onError
#if os(Windows)
	var useColor: Bool = false
#else
	var useColor: Bool = true
#endif
	
	enum KeepWindowOpen: String, Decodable {
		case always, never, onError
		
		var onError: Bool {
			self == .always || self == .onError
		}
	}
	
	var fileTypes: [String] = ["DEP", "DEX", "DMG", "DMS", "DTX", "MAR", "MM3", "MPM", "NDS", "RLS"]
	
	// TODO: skip/only extract
//	var skipExtracting: [String] = []
//	var onlyExtract: [String] = []
	
	var experimental: ExperimentalOptions = ExperimentalOptions()
	
	struct ExperimentalOptions: Decodable {
		var hotReloading: Bool = false
		var postProcessors: [String] = []
		var dexDialogueLabeller: Bool = false
		var dexBlockLabeller: Bool = false
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
	
	static let defaultConfiguration: String = """
		{
			"compressionMode": "auto", // pack, unpack, auto, ask
			"inputFiles": [],
			"outputFolder": null,
			"overwriteOutput": false,
			"showProgress": true,
			"keepWindowOpen": "onError", // always, never, onError
			"useColor": true,
			
			// stable: DEP, DEX, DMG, DMS, DTX, MAR, MM3, MPM, NDS, RLS
			// experimental: 3CL, CHR, DCL, MFS, MMS
			"fileTypes": ["DEP", "DEX", "DMG", "DMS", "DTX", "MAR", "MM3", "MPM", "NDS", "RLS"],
			
			// "skipExtracting": [],
			// "onlyExtract": [],
			
			"experimental": {
				"hotReloading": false, // macOS only
				
				// 3clFinder, mm3Finder, mmsFinder, mpmFinder
				"postProcessors": [],
				
				"dexDialogueLabeller": false,
				"dexBlockLabeller": false
			}
		}
		"""
}

extension CarbonizerConfiguration {
	init(contentsOf path: URL) throws {
		let text: String
		if path.exists() {
			text = try String(contentsOf: path, encoding: .utf8)
		} else {
			text = Self.defaultConfiguration
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
