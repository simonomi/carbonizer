import BinaryParser

enum TCM {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "3CM"
		
		var modelCount: UInt32 = 9
		var modelOffsetsOffset: UInt32 = 0xC
		
		@Count(givenBy: \Self.modelCount)
		@Offset(givenBy: \Self.modelOffsetsOffset)
		var modelOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.modelOffsets)
		var models: [Model]
		
		@BinaryConvertible
		struct Model {
			// 0 for no, 1 for yes
			var isEntry: UInt32
			
			var meshIndex: UInt32
			var meshTableNameOffset: UInt32
			
			var animationIndex: UInt32
			var animationTableNameOffset: UInt32
			
			var textureIndex: UInt32
			var textureTableNameOffset: UInt32
			
			var unknownIndex: UInt32
			var unknownTableNameOffset: UInt32
			
			@If(\Self.isEntry, is: .equalTo(1))
			@Offset(givenBy: \Self.meshTableNameOffset)
			var meshTableName: String?
			
			@If(\Self.isEntry, is: .equalTo(1))
			@Offset(givenBy: \Self.animationTableNameOffset)
			var animationTableName: String?
			
			@If(\Self.isEntry, is: .equalTo(1))
			@Offset(givenBy: \Self.textureTableNameOffset)
			var textureTableName: String?
			
			@If(\Self.isEntry, is: .equalTo(1))
			@Offset(givenBy: \Self.unknownTableNameOffset)
			var unknownTableName: String?
		}
	}
	
	struct Unpacked {
		var models: [Model?]
		
		struct Model: Codable {
			var mesh: TableEntry
			var animation: TableEntry
			var texture: TableEntry
			var unknown: TableEntry
			
			struct TableEntry: Codable {
				var index: UInt32
				var tableName: String
			}
		}
	}
}

// MARK: packed
extension TCM.Packed: ProprietaryFileData {
	static let fileExtension = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> TCM.Unpacked {
		TCM.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: TCM.Unpacked, configuration: Configuration) {
		models = unpacked.models.map(Model.init)
		
		modelOffsets = makeOffsets(
			start: modelOffsetsOffset + 4 * modelCount,
			sizes: models.map(\.size).map(UInt32.init),
			alignedTo: 4
		)
	}
}

extension TCM.Packed.Model {
	fileprivate init(_ unpacked: TCM.Unpacked.Model?) {
		if let unpacked {
			isEntry = 1
			
			meshIndex = unpacked.mesh.index
			animationIndex = unpacked.animation.index
			textureIndex = unpacked.texture.index
			unknownIndex = unpacked.unknown.index
			
			meshTableName = unpacked.mesh.tableName
			animationTableName = unpacked.animation.tableName
			textureTableName = unpacked.texture.tableName
			unknownTableName = unpacked.unknown.tableName
			
			meshTableNameOffset = 0x24
			animationTableNameOffset = meshTableNameOffset + UInt32(meshTableName!.utf8CString.count)
				.roundedUpToTheNearest(4)
			textureTableNameOffset = animationTableNameOffset + UInt32(animationTableName!.utf8CString.count)
				.roundedUpToTheNearest(4)
			unknownTableNameOffset = textureTableNameOffset + UInt32(textureTableName!.utf8CString.count)
				.roundedUpToTheNearest(4)
		} else {
			isEntry = 0
			
			meshIndex = 0
			animationIndex = 0
			textureIndex = 0
			unknownIndex = 0
			
			meshTableName = nil
			animationTableName = nil
			textureTableName = nil
			unknownTableName = nil
			
			meshTableNameOffset = 0
			animationTableNameOffset = 0
			textureTableNameOffset = 0
			unknownTableNameOffset = 0
		}
	}
	
	var size: Int {
		0x24 +
		(meshTableName?.utf8CString.count ?? 0).roundedUpToTheNearest(4) +
		(animationTableName?.utf8CString.count ?? 0).roundedUpToTheNearest(4) +
		(textureTableName?.utf8CString.count ?? 0).roundedUpToTheNearest(4) +
		(unknownTableName?.utf8CString.count ?? 0).roundedUpToTheNearest(4)
	}
}

// MARK: unpacked
extension TCM.Unpacked: ProprietaryFileData {
	static let fileExtension = ".3cm.json"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> TCM.Packed {
		TCM.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: TCM.Packed, configuration: Configuration) {
		models = packed.models.map(Model.init)
	}
}

extension TCM.Unpacked.Model {
	fileprivate init?(_ packed: TCM.Packed.Model) {
		precondition(packed.isEntry <= 1)
		guard packed.isEntry == 1 else { return nil }
		
		mesh = TableEntry(index: packed.meshIndex, tableName: packed.meshTableName!)
		animation = TableEntry(index: packed.animationIndex, tableName: packed.animationTableName!)
		texture = TableEntry(index: packed.textureIndex, tableName: packed.textureTableName!)
		unknown = TableEntry(index: packed.unknownIndex, tableName: packed.unknownTableName!)
	}
}

extension TCM.Unpacked: Codable {
	func encode(to encoder: any Encoder) throws {
		try models.encode(to: encoder)
	}
	
	init(from decoder: any Decoder) throws {
		models = try [Model?](from: decoder)
	}
}
