import BinaryParser

enum VertexData {
	@BinaryConvertible
	struct Packed {
		var unknown1: FixedPoint2012 = 32
		
		var commandsOffset: UInt32 = 0x28
		var commandsLength: UInt32
		
		var boneTableLength: UInt32
		
		var modelNamesLength: UInt32
		
		var unknown2: UInt32 // (1...27).filter(\.isOdd) except 21
		var unknown3: UInt32 // no clue what this number means but when its 0 its all funky
							 // 0, 0x100, 0x101, 0x102
		var unknown4: UInt32 // 1, 2, 3, 4, 5, 6, 9
		var unknown5: UInt32 // lots of values 1...300
							 // number of keyframes?
		
		var unknown6: UInt32 // usually half of 0x8 (commandsLength)??
		
		@Offset(givenBy: \Self.commandsOffset)
		@Length(givenBy: \Self.commandsLength)
		var commands: Datastream
		
		@Offset(givenBy: \Self.commandsOffset, .plus(\Self.commandsLength))
		var boneTable: BoneTable
		
		@Offset(givenBy: \Self.commandsOffset, .plus(\Self.commandsLength), .plus(\Self.boneTableLength))
		var modelNames: ModelNames
		
		@BinaryConvertible
		struct BoneTable {
			var boneCount: UInt32
			
			@Count(givenBy: \Self.boneCount)
			var bones: [Bone]
			
			@BinaryConvertible
			struct Bone {
				@Length(16)
				var name: String
				var matrix: Matrix4x3_2012
			}
		}
		
		@BinaryConvertible
		struct ModelNames {
			var nameCount: UInt32
			
			@Count(givenBy: \Self.nameCount)
			var names: [FixedLengthString]
			
			@BinaryConvertible
			struct FixedLengthString {
				@Length(16)
				var string: String
			}
		}
	}
	
	struct Unpacked: Codable {
		var commandsLength: UInt32
		
		var boneTableLength: UInt32
		
		var modelNamesLength: UInt32
		
		var unknown2: UInt32
		var unknown3: UInt32
		var unknown4: UInt32
		var unknown5: UInt32
		
		var unknown6: UInt32
		
		var commands: [GPUCommand]
		
		var bones: [Bone]
		
		var modelNames: [String]
		
		struct Bone: Codable {
			var name: String
			var matrix: Matrix4x3<Double>
		}
	}
}

// MARK: packed
extension VertexData.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) throws -> VertexData.Unpacked {
		try VertexData.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: VertexData.Unpacked, configuration: Configuration) {
		commandsLength = unpacked.commandsLength
		boneTableLength = unpacked.boneTableLength
		modelNamesLength = unpacked.modelNamesLength
		
		unknown2 = unpacked.unknown2
		unknown3 = unpacked.unknown3
		unknown4 = unpacked.unknown4
		unknown5 = unpacked.unknown5
		unknown6 = unpacked.unknown6
		
//		commands = unpacked.commands
		
		boneTable = BoneTable(
			boneCount: UInt32(unpacked.bones.count),
			bones: unpacked.bones.map(BoneTable.Bone.init)
		)
		
		modelNames = ModelNames(
			nameCount: UInt32(unpacked.modelNames.count),
			names: unpacked.modelNames.map(ModelNames.FixedLengthString.init)
		)
		
		todo()
	}
}

extension VertexData.Packed.BoneTable.Bone {
	fileprivate init(_ unpacked: VertexData.Unpacked.Bone) {
		name = unpacked.name
		matrix = Matrix4x3_2012(unpacked.matrix)
	}
}

// MARK: unpacked
extension VertexData.Unpacked: ProprietaryFileData {
	static let fileExtension = ".vertexData.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: Configuration) -> VertexData.Packed {
		VertexData.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: VertexData.Packed, configuration: Configuration) throws {
		commandsLength = packed.commandsLength
		boneTableLength = packed.boneTableLength
		modelNamesLength = packed.modelNamesLength
		
		unknown2 = packed.unknown2
		unknown3 = packed.unknown3
		unknown4 = packed.unknown4
		unknown5 = packed.unknown5
		unknown6 = packed.unknown6
		
		commands = try packed.commands.readCommands()
		
		bones = packed.boneTable.bones.map(Bone.init)
		
		modelNames = packed.modelNames.names.map(\.string)
	}
}

extension VertexData.Unpacked.Bone {
	fileprivate init(_ packed: VertexData.Packed.BoneTable.Bone) {
		name = packed.name
		matrix = Matrix4x3(packed.matrix)
	}
}

extension SIMD3 where Scalar: FloatingPoint {
	consuming func transformed(by matrix: Matrix4x3<Scalar>) -> Self {
		x * matrix.x + y * matrix.y + z * matrix.z + matrix.transform
	}
}

extension Collection where Index == Int {
	subscript(rel relativeIndex: Index) -> Element {
		self[startIndex + relativeIndex]
	}
}
