import BinaryParser

enum Mesh_FFC {
	@BinaryConvertible
	struct Packed {
		// for ffc, 64, 80, maybe more?
		var unknown1: FixedPoint2012
		
		var commandsOffset: UInt32 = 0x2C
		var commandsLength: UInt32
		
		var boneTableLength: UInt32
		
		var modelNamesLength: UInt32
		
		var unknown2: UInt32
		var unknown3: UInt32
		var unknown4: UInt32
		var unknown5: UInt32
		
		var unknown6: UInt32
		
		var unknownALength: UInt32
		
		@Offset(givenBy: \Self.commandsOffset)
		@Length(givenBy: \Self.commandsLength)
		var commands: ByteSlice
		
		@If(\Self.boneTableLength, is: .notEqualTo(0))
		@Offset(givenBy: \Self.commandsOffset, .plus(\Self.commandsLength))
		var boneTable: BoneTable?
		
		@If(\Self.modelNamesLength, is: .notEqualTo(0))
		@Offset(givenBy: \Self.commandsOffset, .plus(\Self.commandsLength), .plus(\Self.boneTableLength))
		var modelNames: ModelNames?
		
		@Offset(givenBy: \Self.commandsOffset, .plus(\Self.commandsLength), .plus(\Self.boneTableLength), .plus(\Self.modelNamesLength))
		@Length(givenBy: \Self.unknownALength)
		var unknownA: ByteSlice
		
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
				@Count(0x20)
				var unknown: [UInt8]
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
	
	struct Unpacked: Codable, Mesh {
		var unknown1: Double
		var unknown2: UInt32
		var unknown3: UInt32
		var unknown4: UInt32
		var unknown5: UInt32
		
		var unknown6: UInt32
		
		var commands: [MeshCommands.Command]
		
		var bones: [Bone]?
		
		var modelNames: [String]?
		
		var unknownA: [UInt8]
		
		struct Bone: Codable, MeshBone {
			var name: String
			var matrix: Matrix4x3<Double>
			var unknown: [UInt8]
		}
		
		enum MissingCommand: Error, CustomStringConvertible {
			case command51, command52
			
			var description: String {
				switch self {
					case .command51:
						"mesh does not contain the unknown command 51"
					case .command52:
						"mesh does not contain GPU commands"
				}
			}
		}
		
		func gpuCommands() throws -> [GPUCommands.Command] {
			for command in commands {
				if case .unknown52(let gpuCommands) = command {
					return gpuCommands
				}
			}
			
			throw MissingCommand.command52
		}
		
		func worldRootBoneCount() throws -> Int {
			for command in commands {
				if case .unknown51(let bytes) = command {
					// idk, this byte just seems to be the number of 'world_root' bones
					return Int(bytes[12])
				}
			}
			
			throw MissingCommand.command51
		}
	}
}

// MARK: packed
extension Mesh_FFC.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) throws -> Mesh_FFC.Unpacked {
		try Mesh_FFC.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: Mesh_FFC.Unpacked, configuration: Configuration) {
		unknown1 = FixedPoint2012(unpacked.unknown1)
		unknown2 = unpacked.unknown2
		unknown3 = unpacked.unknown3
		unknown4 = unpacked.unknown4
		unknown5 = unpacked.unknown5
		unknown6 = unpacked.unknown6
		
		let writer = Datawriter()
		writer.write(MeshCommands(commands: unpacked.commands))
		commands = writer.bytes
		commandsLength = UInt32(commands.count)
		
		boneTable = unpacked.bones.map {
			BoneTable(
				boneCount: UInt32($0.count),
				bones: $0.map(BoneTable.Bone.init)
			)
		}
		boneTableLength = boneTable.map(\.byteCount) ?? 0
		
		modelNames = unpacked.modelNames.map {
			ModelNames(
				nameCount: UInt32($0.count),
				names: $0.map(ModelNames.FixedLengthString.init)
			)
		}
		modelNamesLength = modelNames.map(\.byteCount) ?? 0
		
		unknownA = unpacked.unknownA[...]
		unknownALength = UInt32(unknownA.count)
	}
}

extension Mesh_FFC.Packed.BoneTable {
	var byteCount: UInt32 {
		4 + boneCount * (16 + (3 * 4 * 4))
	}
}

extension Mesh_FFC.Packed.BoneTable.Bone {
	fileprivate init(_ unpacked: Mesh_FFC.Unpacked.Bone) {
		name = unpacked.name
		matrix = Matrix4x3_2012(unpacked.matrix)
		unknown = unpacked.unknown
	}
}

extension Mesh_FFC.Packed.ModelNames {
	var byteCount: UInt32 {
		4 + nameCount * 16
	}
}

// MARK: unpacked
extension Mesh_FFC.Unpacked: ProprietaryFileData {
	static let fileExtension = ".meshffc.json"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> Mesh_FFC.Packed {
		Mesh_FFC.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: Mesh_FFC.Packed, configuration: Configuration) throws {
		unknown1 = Double(packed.unknown1)
		unknown2 = packed.unknown2
		unknown3 = packed.unknown3
		unknown4 = packed.unknown4
		unknown5 = packed.unknown5
		unknown6 = packed.unknown6
		
		if packed.commandsLength == 0 {
			commands = []
		} else {
			var packedCommands = Datastream(packed.commands)
			commands = try packedCommands.read(MeshCommands.self).commands
		}
		
		bones = packed.boneTable.map {
			$0.bones.map(Bone.init)
		}
		
		modelNames = packed.modelNames.map {
			$0.names.map(\.string)
		}
		
		unknownA = Array(packed.unknownA)
	}
}

extension Mesh_FFC.Unpacked.Bone {
	fileprivate init(_ packed: Mesh_FFC.Packed.BoneTable.Bone) {
		name = packed.name
		matrix = Matrix4x3(packed.matrix)
		unknown = packed.unknown
	}
}
