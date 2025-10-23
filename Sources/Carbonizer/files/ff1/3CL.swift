import BinaryParser

enum TCL { // 3CL
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "3CL"
		
		var vivosaurCount: UInt32
		var indicesOffset: UInt32 = 0xC
		
		@Count(givenBy: \Self.vivosaurCount)
		@Offset(givenBy: \Self.indicesOffset)
		var vivosaurOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.vivosaurOffsets)
		var vivosaurs: [Vivosaur]
		
		@BinaryConvertible
		struct Vivosaur {
			var animationCount: UInt32 // always 8, at least in ff1
			var indicesOffset: UInt32 = 0x8
			
			@Count(givenBy: \Self.animationCount)
			@Offset(givenBy: \Self.indicesOffset)
			var animationOffsets: [UInt32]
			
			@Offsets(givenBy: \Self.animationOffsets)
			var animations: [Animation]
			
			@BinaryConvertible
			struct Animation {
				var isValid: UInt32
				
				var meshIndex: UInt32
				var meshTableNameOffset: UInt32
				
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
				
				@FourByteAlign
				var fourByteAlign: ()
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
				var mesh: TableEntry
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
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> TCL.Unpacked {
		TCL.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: TCL.Unpacked, configuration: Configuration) {
		vivosaurCount = UInt32(unpacked.vivosaurs.count)
		
		vivosaurs = unpacked.vivosaurs.map { Vivosaur($0) }
		
		vivosaurOffsets = makeOffsets(
			start: indicesOffset + 4 * vivosaurCount,
			sizes: vivosaurs.map { $0.size() }
		)
	}
}

extension TCL.Packed.Vivosaur {
	fileprivate init(_ unpacked: TCL.Unpacked.Vivosaur?) {
		// always 8, at least in ff1
		animationCount = UInt32(unpacked?.animations.count ?? 8)
		
		if let unpacked {
			animations = unpacked.animations.map { Animation($0) }
		} else {
			animations = repeatElement(nil, count: Int(animationCount)).map { Animation($0) }
		}
		
		animationOffsets = makeOffsets(
			start: indicesOffset + 4 * animationCount,
			sizes: animations.map(\.size)
		)
	}
	
	func size() -> UInt32 {
		0x8 + animationCount * 4 + animations.map(\.size).sum()
	}
}

extension TCL.Packed.Vivosaur.Animation {
	fileprivate init(_ unpacked: TCL.Unpacked.Vivosaur.Animation?) {
		guard let unpacked else {
			isValid = 0
			meshIndex = 0
			meshTableNameOffset = 0
			animationIndex = 0
			animationTableNameOffset = 0
			textureIndex = 0
			textureTableNameOffset = 0
			
			meshTableName = ""
			animationTableName = ""
			textureTableName = ""
			return
		}
		
		meshTableName = unpacked.mesh.tableName
		animationTableName = unpacked.animation.tableName
		textureTableName = unpacked.texture.tableName
		
		isValid = 1
		
		meshIndex = unpacked.mesh.index
		meshTableNameOffset = 0x1C
		
		animationIndex = unpacked.animation.index
		animationTableNameOffset = meshTableNameOffset + UInt32(meshTableName.utf8CString.count.roundedUpToTheNearest(4))
		
		textureIndex = unpacked.texture.index
		textureTableNameOffset = animationTableNameOffset + UInt32(animationTableName.utf8CString.count.roundedUpToTheNearest(4))
	}
	
	var size: UInt32 {
		if isValid > 0 {
			UInt32(28 + meshTableName.utf8CString.count.roundedUpToTheNearest(4) + animationTableName.utf8CString.count.roundedUpToTheNearest(4) + textureTableName.utf8CString.count.roundedUpToTheNearest(4))
		} else {
			28
		}
	}
}

// MARK: unpacked
extension TCL.Unpacked: ProprietaryFileData {
	static let fileExtension = ".3cl.json"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> TCL.Packed {
		TCL.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: TCL.Packed, configuration: Configuration) {
		vivosaurs = packed.vivosaurs.map {
			Vivosaur(
				animations: $0.animations.map {
					if $0.isValid > 0 {
						Vivosaur.Animation(
							mesh: Vivosaur.Animation.TableEntry(
								index: $0.meshIndex,
								tableName: $0.meshTableName
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
