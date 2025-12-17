import BinaryParser

enum Mesh {
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
		var unknown2: UInt32
		var unknown3: UInt32
		var unknown4: UInt32
		var unknown5: UInt32
		
		var unknown6: UInt32
		
		var commands: [GPUCommands.Command]
		
		var bones: [Bone]
		
		var modelNames: [String]
		
		struct Bone: Codable {
			var name: String
			var matrix: Matrix4x3<Double>
		}
	}
}

// MARK: packed
extension Mesh.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) throws -> Mesh.Unpacked {
		try Mesh.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: Mesh.Unpacked, configuration: Configuration) {
		unknown2 = unpacked.unknown2
		unknown3 = unpacked.unknown3
		unknown4 = unpacked.unknown4
		unknown5 = unpacked.unknown5
		unknown6 = unpacked.unknown6
		
		let writer = Datawriter()
		writer.write(GPUCommands(commands: unpacked.commands))
		commands = writer.intoDatastream()
		commandsLength = UInt32(commands.bytes.count)
		
		boneTable = BoneTable(
			boneCount: UInt32(unpacked.bones.count),
			bones: unpacked.bones.map(BoneTable.Bone.init)
		)
		boneTableLength = boneTable.byteCount
		
		modelNames = ModelNames(
			nameCount: UInt32(unpacked.modelNames.count),
			names: unpacked.modelNames.map(ModelNames.FixedLengthString.init)
		)
		modelNamesLength = modelNames.byteCount
	}
}

extension Mesh.Packed.BoneTable {
	var byteCount: UInt32 {
		4 + boneCount * (16 + (3 * 4 * 4))
	}
}

extension Mesh.Packed.BoneTable.Bone {
	fileprivate init(_ unpacked: Mesh.Unpacked.Bone) {
		name = unpacked.name
		matrix = Matrix4x3_2012(unpacked.matrix)
	}
}

extension Mesh.Packed.ModelNames {
	var byteCount: UInt32 {
		4 + nameCount * 16
	}
}

// MARK: unpacked
extension Mesh.Unpacked: ProprietaryFileData {
	static let fileExtension = ".mesh.json"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> Mesh.Packed {
		Mesh.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: Mesh.Packed, configuration: Configuration) throws {
		unknown2 = packed.unknown2
		unknown3 = packed.unknown3
		unknown4 = packed.unknown4
		unknown5 = packed.unknown5
		unknown6 = packed.unknown6
		
		commands = try packed.commands.read(GPUCommands.self).commands
		
		bones = packed.boneTable.bones.map(Bone.init)
		
		modelNames = packed.modelNames.names.map(\.string)
	}
}

extension Mesh.Unpacked.Bone {
	fileprivate init(_ packed: Mesh.Packed.BoneTable.Bone) {
		name = packed.name
		matrix = Matrix4x3(packed.matrix)
	}
}

extension SIMD3 where Scalar: FloatingPoint {
	consuming func transformed(by matrix: Matrix4x3<Scalar>) -> Self {
		x * matrix.x + y * matrix.y + z * matrix.z + matrix.translation
	}
}

extension Collection where Index == Int {
	subscript(rel relativeIndex: Index) -> Element {
		self[startIndex + relativeIndex]
	}
}
