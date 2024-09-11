import ArgumentParser
import Foundation

struct CarbonizerConfiguration: Decodable {
	var compressionMode: CompressionMode
	var inputFiles: [String]
	var outputFolder: String?
	var overwriteOutput: Bool
	
	var fileTypes: [String]
	
	// TODO: skip/only extract
//	var skipExtracting: [String]
//	var onlyExtract: [String]
	
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
			
			// stable: DEX, DMG, DMS, DTX, MAR, MM3, MPM, NDS, RLS
			// experimental: CHR, DCL, MFS, MMS
			"fileTypes": ["DEX", "DMG", "DMS", "DTX", "MAR", "MM3", "MPM", "NDS", "RLS"],
			
			// "skipExtracting": [],
			// "onlyExtract": [],

			"experimental": {
				"hotReloading": false, // macOS only
				
				// mm3Finder, mmsFinder, mpmFinder
				"postProcessors": []
			}
		}
		"""
}

extension CarbonizerConfiguration {
	init(contentsOf path: URL) throws {
		let text: String
		if path.exists() {
			text = try String(contentsOf: path)
		} else {
			text = Self.defaultConfiguration
			try text.write(to: path, atomically: true, encoding: .utf8)
		}
		
		self = try Self(decoding: text)
	}
	
	init(decoding text: String) throws {
		let commentRegex = #/\/\/.*/#
		let textWithoutComments = text.replacing(commentRegex, with: "")
		
		let data = textWithoutComments.data(using: .utf8)!
		
		self = try JSONDecoder().decode(Self.self, from: data)
	}
}
