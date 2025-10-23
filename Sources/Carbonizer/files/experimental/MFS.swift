import BinaryParser

enum MFS {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "MFS"
		var someCount: UInt32
		var someOffsetsOffset: UInt32 = 0xC
		@Count(givenBy: \Self.someCount)
		@Offset(givenBy: \Self.someOffsetsOffset)
		var someOffsets: [UInt32]
		
		@Offsets(givenBy: \Self.someOffsets)
		var somes: [Something]
		
		@BinaryConvertible
		struct Something: Codable {
			var colorPaletteCount: UInt32
			var unknown2: UInt32 // correlates with unknown7 being 2
			var unknown3: UInt32 // always 2 if unknown2 is 1 (and sometimes if not)
								 // whether this file has multiple..... Somethings?
								 // - 1 for no, 2 for yes
			var letterSize: UInt32
			var unknown5: UInt32 = 0
			var letterCount: UInt32
			var unknown7: UInt32
			var unknown8: UInt32
			var unknown9: UInt32
			var unknown10: UInt32
			var colorPaletteSize: UInt32
			var colorPaletteOffset: UInt32 = 0x38
			var lettersSize: UInt32
			var lettersOffset: UInt32
			
//			@Count(givenBy: \Self.colorPaletteCount)
//			@Offset(givenBy: \Self.colorPaletteOffset)
//			var colorPalettes: [Palette]
			
//			@If(\Self.letterSize, is: .equalTo(16)) // skip every font but font12
			@If(\Self.letterSize, is: .equalTo(0x44)) // skip every font but font12
													  // font10 seems to fail bc non-ascii
													  // rv_num seems to fail bc direct color bitmap
			@Offset(givenBy: \Self.lettersOffset)
			@Count(givenBy: \Self.letterCount)
			var letters: [Letter]?
			
//			struct Palette: Codable {
//				@Count(0x20)
//				var colors: [UInt8] // rgb555 probably
//			}
			
			@BinaryConvertible
			struct Letter: Codable {
				var unknown: UInt8 // which palette? just spitballing here
				var ascii: UInt8
				var width: UInt8
				var height: UInt8
//				@Count(givenBy: \Self.width, .times(\Self.height), .dividedBy(2)) // uhhh (divided by 8 for b/w)
				@Count(0x40)
				var letterData: [UInt8] // if no palette, bitmask one byte per row
										// if palette, 4 bits per color
				
			}
		}
	}
	
	struct Unpacked: Codable {}
}

// MARK: packed
extension MFS.Packed: ProprietaryFileData {
	static let fileExtension = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> MFS.Unpacked {
		MFS.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: MFS.Unpacked, configuration: Configuration) {
		todo()
	}
}

// MARK: unpacked
extension MFS.Unpacked: ProprietaryFileData {
	static let fileExtension = ".mfs.json"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> MFS.Packed {
		MFS.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: MFS.Packed, configuration: Configuration) {
		print()
		print(packed.someCount)
		
		guard packed.someCount == 1 else { return }
//		guard packed.someCount == 3 else { return }
		
		let something = packed.somes.first!
		
		print(something.letterSize)
		
//		guard something.letterLength == 16 else { return }
		guard something.letterSize == 0x44 else { return }
		
		print("here")
		
		for letter in something.letters! {
//			let letterString = letter.letterData
//				.map { String($0, radix: 2) }
//				.map { $0.padded(toLength: 8, with: "0") }
//				.joined(separator: "\n")
//				.replacing("0", with: " ")
//				.replacing("1", with: "█")
//			
//			print(letterString)
			print(String(letter.ascii, radix: 16))
//			print(letter.letterData)
			print(
				letter.letterData
					.flatMap { [$0 & 0b1111, $0 >> 4] }
					.map { String($0, radix: 16) }
					.chunked(exactSize: Int(letter.width))
					.joined(separator: ["\n"])
					.joined(separator: "")
			)
			print("---")
		}
		
		todo()
	}
}
