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
		
		var paletteFiles: [[String]: Set<Int>]?
		var bitmapFiles: [[String]: Set<Int>]?
		var bgMapFiles: [[String]: Set<Int>]?
		
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
		
		var _imageTableNameCache: Set<[String]>?
		mutating func imageTableNames() throws -> Set<[String]> {
			if let _imageTableNameCache {
				return _imageTableNameCache
			} else {
				_imageTableNameCache = Set(try get(\.paletteFiles).keys)
					.union(try get(\.bitmapFiles).keys)
					.union(try get(\.bgMapFiles).keys)
				
				return _imageTableNameCache!
			}
		}
		
		var foldersWithTextureArchives: Set<[String]>?
		
		//                  folder    table
		var modelIndices: [[String]: [String: Set<ModelIndices>]]?
		var imageIndices: [[String]: [String: Set<ImageIndices>]]?
		
		struct ModelIndices: Hashable {
			var modelName: String
			var meshIndex: Int
			var textureIndex: Int
			var animationIndex: Int
		}
		
		struct ImageIndices: Hashable {
			var imageName: String
			var width: UInt32
			var height: UInt32
			var paletteIndex: Int
			var bitmapIndex: Int
			var bgMapIndex: Int?
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
