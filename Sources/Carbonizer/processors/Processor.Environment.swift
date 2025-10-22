extension Processor {
	struct Environment {
		var text: [String: [String]]?
		var dialogue: [UInt32: String]?
		var eventIDs: [String: [Int32]]?
		
		// dialogue ripped from DEX files
		var conflictedDexDialogue: [UInt32: WithPossibleMergeConflict<String>]?
		var dexDialogue: [UInt32: String]?
		
		var meshFiles: [[String]: Set<Int>]?
		var textureFiles: [[String]: Set<Int>]?
		var modelAnimationFiles: [[String]: Set<Int>]?
		
		var imagePaletteFiles: [[String]: Set<Int>]?
		var imageBitmapFiles: [[String]: Set<Int>]?
		var bgMapFiles: [[String]: Set<Int>]?
		
		var spriteAnimationFiles: [[String]: Set<Int>]?
		var spritePaletteFiles: [[String]: Set<Int>]?
		var spriteBitmapFiles: [[String]: Set<Int>]?
		
		var _modelTableNameCache: Set<[String]>?
		mutating func modelTableNames() throws -> Set<[String]> {
			if let _modelTableNameCache {
				return _modelTableNameCache
			} else {
				_modelTableNameCache = Set(try get(\.meshFiles).keys)
					.union(try get(\.textureFiles).keys)
					.union(try get(\.modelAnimationFiles).keys)
				
				return _modelTableNameCache!
			}
		}
		
		var _imageTableNameCache: Set<[String]>?
		mutating func imageTableNames() throws -> Set<[String]> {
			if let _imageTableNameCache {
				return _imageTableNameCache
			} else {
				_imageTableNameCache = Set(try get(\.imagePaletteFiles).keys)
					.union(try get(\.imageBitmapFiles).keys)
					.union(try get(\.bgMapFiles).keys)
				
				return _imageTableNameCache!
			}
		}
		
		var _spriteTableNameCache: Set<[String]>?
		mutating func spriteTableNames() throws -> Set<[String]> {
			if let _spriteTableNameCache {
				return _spriteTableNameCache
			} else {
				_spriteTableNameCache = Set(try get(\.spriteAnimationFiles).keys)
					.union(try get(\.spritePaletteFiles).keys)
					.union(try get(\.spriteBitmapFiles).keys)
				
				return _spriteTableNameCache!
			}
		}
		
		var foldersWithTextureArchives: Set<[String]>?
		
		//                  folder    table
		var modelIndices: [[String]: [String: Set<ModelIndices>]]?
		var imageIndices: [[String]: [String: Set<ImageIndices>]]?
		var spriteIndices: [[String]: [String: Set<SpriteIndices>]]?
		
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
		
		struct SpriteIndices: Hashable {
			var spriteName: String
			// color palette count?
			var animationIndices: [Int]
			var paletteIndices: [Int]
			var bitmapIndices: [Int]
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
