import BinaryParser

@BinaryConvertible
struct AnimationData {
	var unknownA: UInt32 = 0x20000
	
	var unknown1Offset: UInt32 = 0x28
	
	var unknown1Size: UInt32
	
	var includedModelsSize: UInt32
	
	var unknown2Size: UInt32
	
	var keyframesSize: UInt32
	
	var keyframeCount: UInt32 // only affected the head for hunter and rosie
	
	var unknown1WordCount: UInt32
	
	var unknown3: UInt32 // only nonzero for
						 // o02door1_01 - 8
						 // o08iwa3_2_01 - 96
						 // swing0 - 104
						 // testman - 361
	
	var includedModelsWordCount: UInt32
	
	@Offset(givenBy: \Self.unknown1Offset)
	@Count(givenBy: \Self.unknown1WordCount)
	var unknown1: [UInt32]
//    - the first one is 0
//    - the last one is one less than the number of frames
//    - roughly evenly spaced
//    - changing them doesnt do anything as far as i can tell
	
	@Offset(
		givenBy: \Self.unknown1Offset,
		.plus(\Self.unknown1Size)
	)
	@Count(givenBy: \Self.includedModelsWordCount)
	var includedModels: [UInt32]
	// 1 word per model, often see `83 1F ...`
	
	@Offset(
		givenBy: \Self.unknown1Offset,
		.plus(\Self.unknown1Size),
		.plus(\Self.includedModelsSize)
	)
	@Count(givenBy: \Self.unknown2Size)
	var unknown2: [UInt8]
//        unknown word
//        consecutive transform matrices
	
	@Offset(
		givenBy: \Self.unknown1Offset,
		.plus(\Self.unknown1Size),
		.plus(\Self.includedModelsSize),
		.plus(\Self.unknown2Size)
	)
	var keyframes: Keyframes
	
	@BinaryConvertible
	struct Keyframes {
		var boneCount: UInt32
		var frameCount: UInt32 // only affected the body for hunter and rosie
		
		@Count(givenBy: \Self.boneCount, .times(\Self.frameCount))
		var transforms: [Matrix4x3_2012]
	}
}
