import BinaryParser

enum Mesh {
	@BinaryConvertible
	struct Packed {
		// for ff1, always 32
		// for ffc, 64, 80, maybe more?
		var unknown1: FixedPoint2012
		
		// for ff1, always 0x28
		// for ffc, always 0x2C
		var commandsOffset: UInt32
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
		
		@If(\Self.commandsOffset, is: .equalTo(0x2C))
		var unknownALength: UInt32?
		
		@Offset(givenBy: \Self.commandsOffset)
		@Length(givenBy: \Self.commandsLength)
		var commands: ByteSlice
		
		@If(\Self.boneTableLength, is: .notEqualTo(0))
		@Offset(givenBy: \Self.commandsOffset, .plus(\Self.commandsLength))
		var boneTable: BoneTable?
		
		@If(\Self.modelNamesLength, is: .notEqualTo(0))
		@Offset(givenBy: \Self.commandsOffset, .plus(\Self.commandsLength), .plus(\Self.boneTableLength))
		var modelNames: ModelNames?
		
		@If(\Self.unknownALength, is: .notEqualTo(nil))
		@Offset(givenBy: \Self.commandsOffset, .plus(\Self.commandsLength), .plus(\Self.boneTableLength), .plus(\Self.modelNamesLength))
		@Length(givenBy: \Self.unknownALength!)
		var unknownA: ByteSlice?
		
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
		var unknown1: Double
		var unknown2: UInt32
		var unknown3: UInt32
		var unknown4: UInt32
		var unknown5: UInt32
		
		var unknown6: UInt32
		
		var commands: [MeshCommands.Command]
		
		var bones: [Bone]?
		
		var modelNames: [String]?
		
		var unknownA: [UInt8]?
		
		struct Bone: Codable {
			var name: String
			var matrix: Matrix4x3<Double>
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
extension Mesh.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) throws -> Mesh.Unpacked {
		try Mesh.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: Mesh.Unpacked, configuration: Configuration) {
		unknown1 = FixedPoint2012(unpacked.unknown1)
		unknown2 = unpacked.unknown2
		unknown3 = unpacked.unknown3
		unknown4 = unpacked.unknown4
		unknown5 = unpacked.unknown5
		unknown6 = unpacked.unknown6
		
		self.commandsOffset = if unpacked.unknownA == nil {
			0x28
		} else {
			0x2C
		}
		
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
		
		unknownA = unpacked.unknownA.map { $0[...] }
		unknownALength = unknownA.map { UInt32($0.count) }
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
		
		unknownA = packed.unknownA.map(Array.init)
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
