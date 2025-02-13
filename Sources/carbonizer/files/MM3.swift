import BinaryParser

struct MM3 {
	var model: TableEntry
	var animation: TableEntry
	var texture: TableEntry
	
	struct TableEntry {
		var index: UInt32
		var tableName: String
	}
	
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "MM3"
		var modelIndex: UInt32
		var modelTableNameOffset: UInt32
		var animationIndex: UInt32
		var animationTableNameOffset: UInt32
		var textureIndex: UInt32
		var textureTableNameOffset: UInt32
		@Offset(givenBy: \Self.modelTableNameOffset)
		var modelTableName: String
		@Offset(givenBy: \Self.animationTableNameOffset)
		var animationTableName: String
		@Offset(givenBy: \Self.textureTableNameOffset)
		var textureTableName: String
	}
}

// MARK: packed
extension MM3: ProprietaryFileData, BinaryConvertible {
	static let fileExtension = ".mm3.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	init(_ packed: Binary, configuration: CarbonizerConfiguration) {
		model = TableEntry(index: packed.modelIndex, tableName: packed.modelTableName)
		animation = TableEntry(index: packed.animationIndex, tableName: packed.animationTableName)
		texture = TableEntry(index: packed.textureIndex, tableName: packed.textureTableName)
	}
}

extension MM3.Binary: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	init(_ mm3: MM3, configuration: CarbonizerConfiguration) {
		modelIndex = mm3.model.index
		animationIndex = mm3.animation.index
		textureIndex = mm3.texture.index
		
		modelTableName = mm3.model.tableName
		animationTableName = mm3.animation.tableName
		textureTableName = mm3.texture.tableName
		
		modelTableNameOffset = 0x1C
		animationTableNameOffset = modelTableNameOffset + UInt32(animationTableName.utf8CString.count)
		textureTableNameOffset = animationTableNameOffset + UInt32(textureTableName.utf8CString.count)
	}
}

// MARK: unpacked
extension MM3: Codable {
	enum CodingKeys: String, CodingKey {
		case model = "model"
		case animation = "animation"
		case texture = "texture"
	}
}

extension MM3.TableEntry: Codable {
	enum CodingKeys: String, CodingKey {
		case index =     "index"
		case tableName = "table name"
	}
}
