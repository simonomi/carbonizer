import Foundation

public struct Configuration: Sendable {
	var overwriteOutput: Bool
	var dexCommandList: DEXCommandList // TODO: more general ff1/ffc
	var externalMetadata: Bool
	
	var fileTypes: Set<String>
	
	var onlyUnpack: [Glob]
	var skipUnpacking: [Glob]
	
	var processors: Set<Processor>
	
	var cache: Cache
	
	var logHandler: (@Sendable (String) -> Void)?
	
	public enum DEXCommandList: Sendable {
		case ff1, ffc, none
	}
	
	public struct ExperimentalOptions: Sendable {
		var postProcessors: [String]
		var dexDialogueLabeller: Bool
		var dexDialogueSaver: Bool
		var dexBlockLabeller: Bool
		var dbsNameLabeller: Bool
		var hmlNameLabeller: Bool
		var keyItemLabeller: Bool
		var mapLabeller: Bool
		var museumLabeller: Bool
		
		public init(postProcessors: [String], dexDialogueLabeller: Bool, dexDialogueSaver: Bool, dexBlockLabeller: Bool, dbsNameLabeller: Bool, hmlNameLabeller: Bool, keyItemLabeller: Bool, mapLabeller: Bool, museumLabeller: Bool) {
			self.postProcessors = postProcessors
			self.dexDialogueLabeller = dexDialogueLabeller
			self.dexDialogueSaver = dexDialogueSaver
			self.dexBlockLabeller = dexBlockLabeller
			self.dbsNameLabeller = dbsNameLabeller
			self.hmlNameLabeller = hmlNameLabeller
			self.keyItemLabeller = keyItemLabeller
			self.mapLabeller = mapLabeller
			self.museumLabeller = museumLabeller
		}
	}
	
	struct Cache {
		var fileExtensions: [(extension: String, type: any ProprietaryFileData.Type)]
		var magicBytes: [String: any ProprietaryFileData.Type]
		
		init(inputFileTypes: Set<String>) {
			let enabledFileTypes: [any ProprietaryFileData.Type] = Configuration.allFileTypes
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
	
	public init(overwriteOutput: Bool, dexCommandList: DEXCommandList, externalMetadata: Bool, fileTypes: Set<String>, onlyUnpack: [Glob], skipUnpacking: [Glob], processors: Set<Processor>, logHandler: (@Sendable (String) -> Void)?) throws {
		self.overwriteOutput = overwriteOutput
		self.dexCommandList = dexCommandList
		self.externalMetadata = externalMetadata
		self.fileTypes = fileTypes
		self.onlyUnpack = onlyUnpack
		self.skipUnpacking = skipUnpacking
		self.processors = processors
		self.logHandler = logHandler
		
		let allowedInputFileTypes = Self.allFileTypes.keys + ["MAR", "NDS", "_match"]
		
		guard fileTypes.allSatisfy(allowedInputFileTypes.contains) else {
			throw UnsupportedFileTypes(
				fileTypes: fileTypes
					.filter { !allowedInputFileTypes.contains($0) }
					.sorted()
			)
		}
		
		cache = Cache(inputFileTypes: fileTypes)
	}
	
	func log(_ items: Any...) {
		guard let logHandler else { return }
		
		logHandler(
			items
				.map { String(describing: $0) }
				.joined(separator: " ")
		)
	}
	
	// when adding a new stable filetype:
	// - add to this list
	// - add round trip tests
	// - test entire rom ff1 round trip
	// - test entire rom ffc round trip
	// - add to config (test both ff1/ffc)
	// - add to fftechwiki
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
