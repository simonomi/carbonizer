import BinaryParser

enum MM3_FF1 {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "MM3"
		
		var meshIndex: UInt32
		var meshTableNameOffset: UInt32 = 0x1C
		
		var animationIndex: UInt32
		var animationTableNameOffset: UInt32
		
		var textureIndex: UInt32
		var textureTableNameOffset: UInt32
		
		@Offset(givenBy: \Self.meshTableNameOffset)
		var meshTableName: String
		
		@Offset(givenBy: \Self.animationTableNameOffset)
		var animationTableName: String
		
		@Offset(givenBy: \Self.textureTableNameOffset)
		var textureTableName: String
	}
	
	struct Unpacked: Codable {
		var mesh: TableEntry
		var animation: TableEntry
		var texture: TableEntry
		
		struct TableEntry: Codable {
			var index: UInt32
			var tableName: String
		}
	}
}

// MARK: packed
extension MM3_FF1.Packed: ProprietaryFileData {
	static let fileExtension = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> MM3_FF1.Unpacked {
		MM3_FF1.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: MM3_FF1.Unpacked, configuration: Configuration) {
		meshIndex = unpacked.mesh.index
		animationIndex = unpacked.animation.index
		textureIndex = unpacked.texture.index
		
		meshTableName = unpacked.mesh.tableName
		animationTableName = unpacked.animation.tableName
		textureTableName = unpacked.texture.tableName
		
		animationTableNameOffset = meshTableNameOffset + UInt32(animationTableName.utf8CString.count)
			.roundedUpToTheNearest(4)
		textureTableNameOffset = animationTableNameOffset + UInt32(textureTableName.utf8CString.count)
			.roundedUpToTheNearest(4)
	}
}

// MARK: unpacked
extension MM3_FF1.Unpacked: ProprietaryFileData {
	static let fileExtension = ".mm3.json"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> MM3_FF1.Packed {
		MM3_FF1.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: MM3_FF1.Packed, configuration: Configuration) {
		mesh = TableEntry(index: packed.meshIndex, tableName: packed.meshTableName)
		animation = TableEntry(index: packed.animationIndex, tableName: packed.animationTableName)
		texture = TableEntry(index: packed.textureIndex, tableName: packed.textureTableName)
	}
}
