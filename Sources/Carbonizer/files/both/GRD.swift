import BinaryParser

// map c zooms the camera ? and maybe more? sub areas??
// map e is fossil rock areas
// map g may have something to do with the rocks that spawn in digsites
// map r collision boxes?

enum GRD {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "GRD"
		
		var width: UInt32
		var height: UInt32
		
		var byteCount: UInt32 // always width * height
		var offset: UInt32 = 0x14
		
		@Offset(givenBy: \Self.offset)
		@Length(givenBy: \Self.byteCount)
		var gridData: ByteSlice
		
		@FourByteAlign
		var fourByteAlign: ()
	}
	
	struct Unpacked {
		var data: [[UInt8]]
	}
}

// MARK: packed
extension GRD.Packed: ProprietaryFileData {
	static let fileExtension = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> GRD.Unpacked {
		GRD.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: GRD.Unpacked, configuration: Configuration) {
		width = UInt32(unpacked.data[0].count)
		height = UInt32(unpacked.data.count)
		
		byteCount = width * height
		
		gridData = unpacked.data.flatMap { $0 }[...]
	}
}

// MARK: unpacked
extension GRD.Unpacked: ProprietaryFileData {
	static let fileExtension = ".grd.txt"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> GRD.Packed {
		GRD.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: GRD.Packed, configuration: Configuration) {
		data = packed.gridData
			.chunked(maxSize: Int(packed.width))
			.map(Array.init)
	}
	
	// the maximum byte used is 57, so we need a set of at least 57 characters to use
	static let alphabet = " 123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	
	static let letterLookup = alphabet.split(separator: "")
	
	static let byteLookup: [Character: UInt8] = Dictionary(
		uniqueKeysWithValues: alphabet
			.enumerated()
			.map { ($1, UInt8($0)) }
	)
	
	enum ReadError: Error, CustomStringConvertible {
		case invalidLetter(Character)
		case mismatchedRowCounts([Int])
		
		var description: String {
			switch self {
				case .invalidLetter(let letter):
					"invalid letter in grid: \(.red)'\(letter)'\(.normal), valid letters are space, 1–9, a–z, and A–Z"
				case .mismatchedRowCounts(let rowCounts):
					"mismatching row counts: \(rowCounts)"
			}
		}
	}
	
	init(_ data: inout Datastream, configuration: Configuration) throws {
		let dataCount = data.bytesInRange.indices.count
		let raw = try data.read(String.self, exactLength: dataCount)
		
		self.data = [[]]
		for character in raw {
			if character == "\n" {
				self.data.append([])
			} else {
				guard let byte = Self.byteLookup[character] else {
					throw ReadError.invalidLetter(character)
				}
				
				self.data[self.data.endIndex - 1].append(byte)
			}
		}
		
		if self.data.last!.isEmpty {
			self.data.removeLast()
		}
		
		guard self.data.allSatisfy({ $0.count == self.data[0].count }) else {
			throw ReadError.mismatchedRowCounts(self.data.map(\.count))
		}
	}
	
	func write(to data: Datawriter) {
		for row in self.data {
			for byte in row {
				data.write(String(Self.letterLookup[Int(byte)]), length: 1)
			}
			data.write("\n", length: 1)
		}
	}
}
