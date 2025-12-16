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
		
		var animationLength: UInt32 // only affected the head for hunter and rosie
		
		// TODO: are this and includedModels variable-sized, and these are different size and count fields?
		// i dont think so, bc battle 250 has 0xf0 and 0x1 as its two values
		var unknown4: UInt32 // usually unknown2Size / 4
		
		var unknown1: UInt32 // only nonzero for
							 // o02door1_01 - 8
							 // o08iwa3_2_01 - 96
							 // swing0 - 104
							 // testman - 361
		
		var unknown5: UInt32 // usually includedModelsSize / 4
		
		@Offset(givenBy: \Self.unknown2Offset)
		@Count(givenBy: \Self.unknown2Size, .dividedBy(4))
		var unknown2: [UInt32]
		// - the first one is 0
		// - the last one is one less than the number of frames
		// - roughly evenly spaced
		// - changing them doesnt do anything as far as i can tell
		
		@Offset(
			givenBy: \Self.unknown2Offset,
			.plus(\Self.unknown2Size)
		)
		@Count(givenBy: \Self.includedModelsSize, .dividedBy(4))
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
		var animationLength: UInt32
		
		var unknown1: UInt32
		
		var unknown2: [UInt32]
		
		var includedModels: [UInt32]
		
		var unknown3: [UInt8]
		
		var unknown4: UInt32
		
		var unknown5: UInt32
		
		var keyframes: [[Matrix4x3<Double>]]
	}
}

// MARK: packed
extension Animation.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> Animation.Unpacked {
		Animation.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: Animation.Unpacked, configuration: Configuration) {
		unknown1 = unpacked.unknown1
		
		unknown2 = unpacked.unknown2
		unknown4 = unpacked.unknown4
		unknown2Size = UInt32(unknown2.count) * 4
		
		includedModels = unpacked.includedModels
		unknown5 = unpacked.unknown5
		includedModelsSize = UInt32(includedModels.count) * 4
		
		unknown3 = unpacked.unknown3
		unknown3Size = UInt32(unknown3.count)
		
		keyframes = Keyframes(unpacked.keyframes)
		animationLength = unpacked.animationLength
		keyframesSize = 8 + keyframes.boneCount * keyframes.frameCount * 4 * 3 * 4
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
	
	func packed(configuration: Configuration) -> Animation.Packed {
		Animation.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: Animation.Packed, configuration: Configuration) {
		animationLength = packed.animationLength
		
		unknown1 = packed.unknown1
		
		unknown2 = packed.unknown2
		
		includedModels = packed.includedModels
		
		unknown3 = packed.unknown3
		
		unknown4 = packed.unknown4
		unknown5 = packed.unknown5
		
		keyframes = packed.keyframes.transforms
			.chunked(exactSize: Int(packed.keyframes.boneCount))
			.recursiveMap(Matrix4x3.init)
	}
}
