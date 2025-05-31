import BinaryParser

// 3CL
enum TCL {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "3CL"
		var vivosaurCount: UInt32
		var indicesOffset: UInt32
		
		@Count(givenBy: \Self.vivosaurCount)
		@Offset(givenBy: \Self.indicesOffset)
		var vivosaurOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.vivosaurOffsets)
		var vivosaurs: [Vivosaur]
		
		@BinaryConvertible
		struct Vivosaur {
			var animationCount: UInt32
			var indicesOffset: UInt32
			
			@Count(givenBy: \Self.animationCount)
			@Offset(givenBy: \Self.indicesOffset)
			var animationOffsets: [UInt32]
			
			@Offsets(givenBy: \Self.animationOffsets)
			var animations: [Animation]
			
			@BinaryConvertible
			struct Animation {
				var isValid: UInt32
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
	}
	
	struct Unpacked: Codable {
		var vivosaurs: [Vivosaur?]
		
		struct Vivosaur: Codable {
			var animations: [Animation?]
			
			init?(animations: [Animation?]) {
				if animations.allSatisfy({ $0 == nil }) { return nil }
				
				self.animations = animations
			}
			
			struct Animation: Codable {
				var model: TableEntry
				var animation: TableEntry
				var texture: TableEntry
				
				struct TableEntry: Codable {
					var index: UInt32
					var tableName: String
				}
			}
		}
	}
}

// MARK: packed
extension TCL.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> TCL.Unpacked {
		TCL.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: TCL.Unpacked, configuration: CarbonizerConfiguration) {
		todo()
	}
}

// MARK: unpacked
extension TCL.Unpacked: ProprietaryFileData {
	static let fileExtension = ".3cl.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> TCL.Packed {
		TCL.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: TCL.Packed, configuration: CarbonizerConfiguration) {
		vivosaurs = packed.vivosaurs.map {
			Vivosaur(
				animations: $0.animations.map {
					if $0.isValid > 0 {
						Vivosaur.Animation(
							model: Vivosaur.Animation.TableEntry(
								index: $0.modelIndex,
								tableName: $0.modelTableName
							),
							animation: Vivosaur.Animation.TableEntry(
								index: $0.animationIndex,
								tableName: $0.animationTableName
							),
							texture: Vivosaur.Animation.TableEntry(
								index: $0.textureIndex,
								tableName: $0.textureTableName
							)
						)
					} else {
						nil
					}
				}
			)
		}
	}
}
