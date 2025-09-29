extension Processor {
	struct Environment {
		var text: [String]?
		var ffcText: [String: [String]]?
		var dialogue: [UInt32: String]?
		var blockIDs: [String: [Int32]]?
		
		// dialogue ripped from DEX files
		var conflictedDexDialogue: [UInt32: WithPossibleMergeConflict<String>]?
		var dexDialogue: [UInt32: String]?
		
		var meshFiles: [[String]: Set<Int>]?
		var textureFiles: [[String]: Set<Int>]?
		var animationFiles: [[String]: Set<Int>]?
		
		var _modelTableNameCache: Set<[String]>?
		mutating func modelTableNames() throws -> Set<[String]> {
			if let _modelTableNameCache {
				return _modelTableNameCache
			} else {
				_modelTableNameCache = Set(try get(\.meshFiles).keys)
					.union(try get(\.textureFiles).keys)
					.union(try get(\.animationFiles).keys)
				
				return _modelTableNameCache!
			}
		}
		
		var foldersWithTextureArchives: Set<[String]>?
		
		//                  folder    table
		var modelIndices: [[String]: [String: Set<ModelIndices>]]?
		
		struct ModelIndices: Hashable {
			var modelName: String
			var meshIndex: Int
			var textureIndex: Int
			var animationIndex: Int
		}
		
		struct MissingValue: Error, CustomStringConvertible {
			var path: String
			
			var description: String {
				"missing environment data \(.cyan)'\(path)'\(.normal)"
			}
		}
		
		
		func get<T>(_ path: KeyPath<Self, T?>) throws -> T {
			if let value = self[keyPath: path] {
				value
			} else {
				throw MissingValue(path: path.debugDescription)
			}
		}
	}
}
