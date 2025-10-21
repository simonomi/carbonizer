import BinaryParser

enum Animation {
	@BinaryConvertible
	struct Packed {
		var unknownA: FixedPoint2012 = 32
		
		var unknown2Offset: UInt32 = 0x28
		
		var unknown2Size: UInt32
		
		var includedModelsSize: UInt32
		
		var unknown3Size: UInt32
		
		var keyframesSize: UInt32
		
		var keyframeCount: UInt32 // only affected the head for hunter and rosie
		
		var unknown2WordCount: UInt32
		
		var unknown1: UInt32 // only nonzero for
							 // o02door1_01 - 8
							 // o08iwa3_2_01 - 96
							 // swing0 - 104
							 // testman - 361
		
		var includedModelsWordCount: UInt32
		
		@Offset(givenBy: \Self.unknown2Offset)
		@Count(givenBy: \Self.unknown2WordCount)
		var unknown2: [UInt32]
		// - the first one is 0
		// - the last one is one less than the number of frames
		// - roughly evenly spaced
		// - changing them doesnt do anything as far as i can tell
		
		@Offset(
			givenBy: \Self.unknown2Offset,
			.plus(\Self.unknown2Size)
		)
		@Count(givenBy: \Self.includedModelsWordCount)
		var includedModels: [UInt32]
		// 1 word per model, often see `83 1F ...`
		
		@Offset(
			givenBy: \Self.unknown2Offset,
			.plus(\Self.unknown2Size),
			.plus(\Self.includedModelsSize)
		)
		@Count(givenBy: \Self.unknown3Size)
		var unknown3: [UInt8]
		// unknown word
		// consecutive transform matrices
		
		@Offset(
			givenBy: \Self.unknown2Offset,
			.plus(\Self.unknown2Size),
			.plus(\Self.includedModelsSize),
			.plus(\Self.unknown3Size)
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
	
	struct Unpacked: Codable {
		var unknown1: UInt32
		
		var unknown2: [UInt32]
		
		var includedModels: [UInt32]
		
		var unknown3: [UInt8]
		
		var keyframes: [[Matrix4x3<Double>]]
	}
}

// MARK: packed
extension Animation.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> Animation.Unpacked {
		Animation.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: Animation.Unpacked, configuration: Configuration) {
		todo()
		
		// check that this works
		
//		unknown1 = unpacked.unknown1
//		
//		unknown2 = unpacked.unknown2
//		unknown2WordCount = UInt32(unknown2.count)
//		unknown2Size = unknown2WordCount / 4
//		
//		includedModels = unpacked.includedModels
//		includedModelsWordCount = UInt32(includedModels.count)
//		includedModelsSize = includedModelsWordCount / 4
//		
//		unknown3 = unpacked.unknown3
//		unknown3Size = UInt32(unknown3.count)
//		
//		keyframes = Keyframes(unpacked.keyframes)
//		keyframeCount = UInt32(keyframes.frameCount) // TODO: is this always the same?
//		keyframesSize = keyframes.boneCount * keyframes.frameCount * 4 * 3 * 4
	}
}

extension Animation.Packed.Keyframes {
	fileprivate init(_ unpacked: [[Matrix4x3<Double>]]) {
		boneCount = UInt32(unpacked[0].count)
		frameCount = UInt32(unpacked.count)
		transforms = unpacked.flatMap {
			$0.map(Matrix4x3_2012.init)
		}
	}
}

// MARK: unpacked
extension Animation.Unpacked: ProprietaryFileData {
	static let fileExtension = ".modelAnimation.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: Configuration) -> Animation.Packed {
		Animation.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: Animation.Packed, configuration: Configuration) {
		unknown1 = packed.unknown1
		
		unknown2 = packed.unknown2
		
		includedModels = packed.includedModels
		
		unknown3 = packed.unknown3
		
		keyframes = packed.keyframes.transforms
			.chunked(exactSize: Int(packed.keyframes.boneCount))
			.recursiveMap(Matrix4x3.init)
	}
}
