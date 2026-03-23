import BinaryParser

enum MM3_FFC {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "MM3"
		
		var meshIndex: UInt32
		var meshTableNameOffset: UInt32 = 0x24
		
		var animationIndex: UInt32
		var animationTableNameOffset: UInt32
		
		var textureIndex: UInt32
		var textureTableNameOffset: UInt32
		
		var unknownIndex: UInt32
		var unknownTableNameOffset: UInt32
		
		@Offset(givenBy: \Self.meshTableNameOffset)
		var meshTableName: String
		
		@Offset(givenBy: \Self.animationTableNameOffset)
		var animationTableName: String
		
		@Offset(givenBy: \Self.textureTableNameOffset)
		var textureTableName: String
		
		@Offset(givenBy: \Self.unknownTableNameOffset)
		var unknownTableName: String
	}
	
	struct Unpacked: Codable {
		var mesh: TableEntry
		var animation: TableEntry
		var texture: TableEntry
		var unknown: TableEntry // has a number of lists of index-color(?) pairs
		
		struct TableEntry: Codable {
			var index: UInt32
			var tableName: String
		}
	}
}

// MARK: packed
extension MM3_FFC.Packed: ProprietaryFileData {
	static let fileExtension = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> MM3_FFC.Unpacked {
		MM3_FFC.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: MM3_FFC.Unpacked, configuration: Configuration) {
		meshIndex = unpacked.mesh.index
		animationIndex = unpacked.animation.index
		textureIndex = unpacked.texture.index
		unknownIndex = unpacked.unknown.index
		
		meshTableName = unpacked.mesh.tableName
		animationTableName = unpacked.animation.tableName
		textureTableName = unpacked.texture.tableName
		unknownTableName = unpacked.unknown.tableName
		
		animationTableNameOffset = meshTableNameOffset + UInt32(meshTableName.utf8CString.count)
			.roundedUpToTheNearest(4)
		textureTableNameOffset = animationTableNameOffset + UInt32(animationTableName.utf8CString.count)
			.roundedUpToTheNearest(4)
		unknownTableNameOffset = textureTableNameOffset + UInt32(textureTableName.utf8CString.count)
			.roundedUpToTheNearest(4)
	}
}

// MARK: unpacked
extension MM3_FFC.Unpacked: ProprietaryFileData {
	static let fileExtension = ".mm3.json"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> MM3_FFC.Packed {
		MM3_FFC.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: MM3_FFC.Packed, configuration: Configuration) {
		mesh = TableEntry(index: packed.meshIndex, tableName: packed.meshTableName)
		animation = TableEntry(index: packed.animationIndex, tableName: packed.animationTableName)
		texture = TableEntry(index: packed.textureIndex, tableName: packed.textureTableName)
		unknown = TableEntry(index: packed.unknownIndex, tableName: packed.unknownTableName)
	}
}
