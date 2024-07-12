import BinaryParser

struct MFS: Writeable {
	var somethings: [Binary.Something]
	
	@BinaryConvertible
	struct Binary: Writeable {
		var magicBytes = "MFS"
		var someCount: UInt32
		var someOffset: UInt32
		@Count(givenBy: \Self.someCount)
		@Offset(givenBy: \Self.someOffset)
		var someThings: [UInt32]
		
		@Offsets(givenBy: \Self.someThings)
		var noClue: [Something]
		
		@BinaryConvertible
		struct Something: Codable {
			var colorPaletteCount: UInt32 // palette count
			var unknown2: UInt32 // correlates with unknown7 being 2
			var unknown3: UInt32 // always 2 if unknown2 is 1 (and sometimes if not)
								 // whether this file has multiple..... Somethings?
								 // - 1 for no, 2 for yes
			var letterLength: UInt32
			var unknown5: UInt32 = 0
			var lettersCount: UInt32
			var unknown7: UInt32
			var unknown8: UInt32
			var unknown9: UInt32
			var unknown10: UInt32
			var colorPaletteLength: UInt32
			var colorPaletteOffset: UInt32 = 0x38
			var lettersLength: UInt32
			var lettersOffset: UInt32
			
//			var colorPalettes
			
			@If(\Self.letterLength, is: .equalTo(16))
			@Offset(givenBy: \Self.lettersOffset)
			@Count(givenBy: \Self.lettersCount)
			var letters: [Letter]?
			
			@BinaryConvertible
			struct Letter: Codable {
				var unknown: UInt8
				var ascii: UInt8
				var width: UInt8
				var length: UInt8
				@Count(givenBy: \Self.length)
				var letterData: [UInt8] // if no palette, bitmask one byte per row
								  // if palette, 4 bits per color
			}
		}
	}
}

// MARK: packed
extension MFS: FileData {
	static var packedFileExtension = ""
	static var unpackedFileExtension = "mfs.json"
	
	init(packed: Binary) {
		somethings = []
		
		guard packed.someCount == 3 else { return }
		
		let something = packed.noClue.first!
		
		guard something.letterLength == 16 else { return }
		
		for letter in something.letters! {
			let letterString = letter.letterData
				.map { String($0, radix: 2) }
				.map { $0.padded(toLength: 8, with: "0") }
				.joined(separator: "\n")
				.replacing("0", with: " ")
				.replacing("1", with: "█")
			
			print(letterString)
		}
	}
}

func stringToImage(_ string: String, _ length: Int = 8) -> String {
	string
		.split(separator: " ")
		.map { Int($0, radix: 16)! }
		.map { String($0, radix: 2) }
		.map { $0.padded(toLength: length, with: "0") }
		.joined(separator: "\n")
		.replacing("0", with: " ")
		.replacing("1", with: "█")
}


extension MFS.Binary: InitFrom {
	init(_ mfs: MFS) {
		fatalError("TODO")
	}
}

// MARK: unpacked
extension MFS: Codable {
	// TODO: custom codingkeys?
}
