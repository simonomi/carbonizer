import Foundation

public struct Configuration: Sendable {
	var overwriteOutput: Bool
	var game: Game
	var externalMetadata: Bool
	
	var fileTypes: Set<String>
	
	var onlyUnpack: [Glob]
	var skipUnpacking: [Glob]
	
	var compression: Bool
	
	var processors: Set<Processor>
	
	var cache: Cache
	
	var logHandler: (@Sendable (Log) -> Void)?
	
	public enum Game: Sendable {
		case ff1, ffc
	}
	
	public struct Log {
		public var kind: Kind
		var _message: String
		
		public func message(withColor: Bool) -> String {
			if withColor {
				_message
			} else {
				_message.removingANSICodes()
			}
		}
		
		public enum Kind {
			/// notable points in time, like when a new stage of work is started
			case checkpoint
			/// ongoing work, like which file is being read/decompressed/written
			case transient
			case warning
		}
	}
	
	struct Cache {
		var fileExtensions: [(extension: String, type: any ProprietaryFileData.Type)]
		var magicBytes: [String: any ProprietaryFileData.Type]
		
		init(inputFileTypes: Set<String>, game: Game) {
			let enabledFileTypes: [any ProprietaryFileData.Type] = Configuration.fileTypes(for: game)
				.filter { (fileTypeName, _) in
					inputFileTypes.contains(fileTypeName)
				}
				.flatMap { (_, fileType) in
					fileType.unpackedAndPacked()
				}
			
			let alwaysEnabledFileTypes: [any ProprietaryFileData.Type] = [
				Mesh.Unpacked.self,
				Texture.Unpacked.self,
			]
			
			let fileTypes = enabledFileTypes + alwaysEnabledFileTypes
			
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
	
	public init(overwriteOutput: Bool, game: Game, externalMetadata: Bool, fileTypes: Set<String>, onlyUnpack: [Glob], skipUnpacking: [Glob], compression: Bool, processors: Set<Processor>, logHandler: (@Sendable (Log) -> Void)?) throws {
		self.overwriteOutput = overwriteOutput
		self.game = game
		self.externalMetadata = externalMetadata
		self.fileTypes = fileTypes
		self.onlyUnpack = onlyUnpack
		self.skipUnpacking = skipUnpacking
		self.compression = compression
		self.processors = processors
		self.logHandler = logHandler
		
		let allowedInputFileTypes = Self.fileTypes(for: game).keys + ["MAR", "_match"]
		
		guard fileTypes.allSatisfy(allowedInputFileTypes.contains) else {
			throw UnsupportedFileTypes(
				fileTypes: fileTypes
					.filter { !allowedInputFileTypes.contains($0) }
					.sorted()
			)
		}
		
		cache = Cache(inputFileTypes: fileTypes, game: game)
	}
	
	func log(_ kind: Log.Kind, _ items: Any...) {
		guard let logHandler else { return }
		
		let message = items
			.map { String(describing: $0) }
			.joined(separator: " ")
		
		logHandler(Log(kind: kind, _message: message))
	}
	
	// when adding a new stable filetype:
	// - add to this list
	// - add round trip tests
	// - test entire rom ff1 round trip
	// - test entire rom ffc round trip
	// - add to config (test both ff1/ffc)
	// - add to fftechwiki
	static func fileTypes(for game: Game) -> [String: any ProprietaryFileData.Type] {
		let bothGameFileTypes: [String: any ProprietaryFileData.Type] = [
			"DEX": DEX.Unpacked.self,
			"DMG": DMG.Unpacked.self,
			"DMS": DMS.Unpacked.self,
			"DSL": DSL.Unpacked.self,
			"DTX": DTX.Unpacked.self,
			"GRD": GRD.Unpacked.self,
			"KIL": KIL.Unpacked.self,
			"MMS": MMS.Unpacked.self,
			"MPM": MPM.Unpacked.self,
		]
		
		let gameSpecificFileTypes: [String: any ProprietaryFileData.Type] = switch game {
			case .ff1:
				[
					"3BA": TBA.Unpacked.self,
					"3CL": TCL.Unpacked.self,
					"BBG": BBG.Unpacked.self,
					"BCO": BCO.Unpacked.self,
					"CHR": CHR.Unpacked.self,
					"DAL": DAL.Unpacked.self,
					"DBA": DBA.Unpacked.self,
					"DBS": DBS.Unpacked.self,
					"DBT": DBT.Unpacked.self,
					"DCL": DCL_FF1.Unpacked.self,
					"DEP": DEP.Unpacked.self,
					"DML": DML.Unpacked.self,
					"ECS": ECS.Unpacked.self,
					"HML": HML.Unpacked.self,
					"KPS": KPS.Unpacked.self,
					"MAP": MAP.Unpacked.self,
					"MFS": MFS.Unpacked.self,
					"MM3": MM3.Unpacked.self,
					"RLS": RLS.Unpacked.self,
					"SDAT": SDAT.Unpacked.self,
					"SHP": SHP.Unpacked.self,
				]
			case .ffc:
				[
					"DCL": DCL_FFC.Unpacked.self,
				]
		}
		
		return gameSpecificFileTypes.merging(bothGameFileTypes) { _, _ in
			print("duplicate file type keys for \(game)")
			fatalError()
		}
	}
	
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

extension Configuration {
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
