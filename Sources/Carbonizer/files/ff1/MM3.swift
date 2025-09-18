import BinaryParser

enum MM3 {
	@BinaryConvertible
	struct Packed {
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
	
	struct Unpacked {
		var model: TableEntry
		var animation: TableEntry
		var texture: TableEntry
		
		struct TableEntry {
			var index: UInt32
			var tableName: String
		}
	}
}

// MARK: packed
extension MM3.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: Carbonizer.Configuration) -> Self { self }
	
	func unpacked(configuration: Carbonizer.Configuration) -> MM3.Unpacked {
		MM3.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: MM3.Unpacked, configuration: Carbonizer.Configuration) {
		modelIndex = unpacked.model.index
		animationIndex = unpacked.animation.index
		textureIndex = unpacked.texture.index
		
		modelTableName = unpacked.model.tableName
		animationTableName = unpacked.animation.tableName
		textureTableName = unpacked.texture.tableName
		
		modelTableNameOffset = 0x1C
		animationTableNameOffset = modelTableNameOffset + UInt32(animationTableName.utf8CString.count) // TODO: are these the right offsets??
		textureTableNameOffset = animationTableNameOffset + UInt32(textureTableName.utf8CString.count)
	}
}

// MARK: unpacked
extension MM3.Unpacked: ProprietaryFileData {
	static let fileExtension = ".mm3.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: Carbonizer.Configuration) -> MM3.Packed {
		MM3.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Carbonizer.Configuration) -> Self { self }
	
	fileprivate init(_ packed: MM3.Packed, configuration: Carbonizer.Configuration) {
		model = TableEntry(index: packed.modelIndex, tableName: packed.modelTableName)
		animation = TableEntry(index: packed.animationIndex, tableName: packed.animationTableName)
		texture = TableEntry(index: packed.textureIndex, tableName: packed.textureTableName)
	}
}

// MARK: unpacked codable
extension MM3.Unpacked: Codable {
	enum CodingKeys: String, CodingKey {
		case model = "model"
		case animation = "animation"
		case texture = "texture"
	}
}

extension MM3.Unpacked.TableEntry: Codable {
	enum CodingKeys: String, CodingKey {
		case index =     "index"
		case tableName = "table name"
	}
}
