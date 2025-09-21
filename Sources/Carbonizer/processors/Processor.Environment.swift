extension Processor {
	struct Environment {
		var text: [String]?
		var dialogue: [UInt32: String]?
		var blockIDs: [String: [Int32]]?
		
		// dialogue ripped from DEX files
		var conflictedDexDialogue: [UInt32: WithPossibleMergeConflict<String>]?
		var dexDialogue: [UInt32: String]?
		
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
