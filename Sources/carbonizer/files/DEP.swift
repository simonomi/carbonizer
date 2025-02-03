import BinaryParser

struct DEP {
	var blocks: [Block]
	
	struct Block {
		var id: Int32
		var unknown1: Int32
		var unknown2: Int32
		var requirements: [Requirement]
		
		struct Requirement {
			var type: Int32
			var arguments: [Argument]
			
			struct Argument {
				var unknown1: UInt16
				var unknown2: UInt8
			}
		}
	}
	
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "DEP"
		
		var sceneCount: UInt32
		var sceneOffsetsOffset: UInt32 = 0xC
		@Count(givenBy: \Self.sceneCount)
		@Offset(givenBy: \Self.sceneOffsetsOffset)
		var sceneOffsets: [UInt32]
		@Offsets(givenBy: \Self.sceneOffsets)
		var scenes: [Block]
		
		@BinaryConvertible
		struct Block {
			var id: Int32
			var unknown1: Int32
			var unknown2: Int32
			
			var requirementCount: UInt32
			var requirementOffsetsOffset: Int32 = 0x14
			@Count(givenBy: \Self.requirementCount)
			@Offset(givenBy: \Self.requirementOffsetsOffset)
			var requirementOffsets: [UInt32]
			@Offsets(givenBy: \Self.requirementOffsets)
			var requirements: [Requirement]
			
			@BinaryConvertible
			struct Requirement {
				var type: Int32
				var argumentCount: UInt32
				var argumentOffsetsOffset: UInt32 = 0xC
				@Count(givenBy: \Self.argumentCount)
				@Offset(givenBy: \Self.argumentOffsetsOffset)
				var arguments: [Argument]
				
				@BinaryConvertible
				struct Argument {
					var unknown1: UInt16
					@Padding(bytes: 8)
					var unknown2: UInt8
				}
			}
		}
	}
}

// MARK: packed
extension DEP: ProprietaryFileData {
	static let fileExtension = ".dep.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	init(_ binary: Binary) {
		for thing in binary.scenes {
			print(thing.id, thing.unknown1, thing.unknown2, separator: "\t")
			for requirement in thing.requirements {
				let micros = requirement.arguments
					.map { "\($0.unknown1)\t\($0.unknown2)" }
					.joined(separator: "\t\t")
				print("", requirement.type, micros, separator: "\t")
			}
			print()
		}
		print()
		
		blocks = binary.scenes.map(Block.init)
	}
}

extension DEP.Block {
	init(_ binaryBlock: DEP.Binary.Block) {
		id = binaryBlock.id
		unknown1 = binaryBlock.unknown1
		unknown2 = binaryBlock.unknown2
		requirements = binaryBlock.requirements.map(Requirement.init)
	}
}

extension DEP.Block.Requirement {
	init(_ binaryRequirement: DEP.Binary.Block.Requirement) {
		type = binaryRequirement.type
		arguments = binaryRequirement.arguments.map(Argument.init)
	}
}

extension DEP.Block.Requirement.Argument {
	init(_ binaryArgument: DEP.Binary.Block.Requirement.Argument) {
		unknown1 = binaryArgument.unknown1
		unknown2 = binaryArgument.unknown2
	}
}

extension DEP.Binary: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	init(_ dmg: DEP) {
		todo()
	}
}

// MARK: unpacked
extension DEP: Codable {}
extension DEP.Block: Codable {}
extension DEP.Block.Requirement: Codable {}
extension DEP.Block.Requirement.Argument: Codable {}
