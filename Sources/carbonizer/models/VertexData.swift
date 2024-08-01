import BinaryParser

@BinaryConvertible
struct Matrix4x3_2012 {
	var x: Vector3_2012
	var y: Vector3_2012
	var z: Vector3_2012
	var transform: Vector3_2012
}

@BinaryConvertible
struct Vector3_2012 {
	var x: Fixed2012
	var y: Fixed2012
	var z: Fixed2012
}

@BinaryConvertible
struct Fixed2012 {
	var raw: UInt32
}

@BinaryConvertible
struct VertexData {
	var unknown1: UInt32 = 0x20000
	
	var commandsOffset: UInt32 = 0x28
	var commandsLength: UInt32
	
	var boneTableLength: UInt32
	
	var modelNamesLength: UInt32
	
	var unknown2: UInt32 // (1...27).filter(\.isOdd) except 21
	var unknown3: UInt32 // no clue what this number means but when its 0 its all funky
						 // 0, 0x100, 0x101, 0x102
	var unknown4: UInt32 // 1, 2, 3, 4, 5, 6, 9
	var unknown5: UInt32 // lots of values 1...300
	
	var unknown6: UInt32 // usually half of 0x8??
	
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
