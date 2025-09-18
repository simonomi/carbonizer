import BinaryParser

enum AST {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "AST"
		
		var firstCount: UInt32 = 5
		var firstOffset: UInt32 = 0x14
		
		var unknown3: UInt32 // 2, 11, 26, 27, 31, 42, 43, 44, 45, 53, 151, 152, 153, 154, 155, 159, 160, 161, 162, 163, 164, 239
		var unknown4: UInt32 // 3, 37, 171, 172, 173, 174, 176, 183, 187, 238, 252
		
		@Count(givenBy: \Self.firstCount)
		@Offset(givenBy: \Self.firstOffset)
		var firsts: [UInt32] = [0x28, 0x4C, 0x70, 0x94, 0xB8]
		
		@Offsets(givenBy: \Self.firsts)
		var things: [Thing]
		
		@BinaryConvertible
		struct Thing {
			var unknown1: UInt32 // 1, 6, 7, 8, 9, 12, 14, 15, 16, 19, 20, 21, 22, 24, 32, 33, 38, 47, 50, 51, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 76, 77, 78, 79, 80, 190, 191, 192, 193, 194, 196, 198, 199, 200, 201, 203, 204, 205, 206, 207, 208, 210, 211, 212, 215, 216, 217, 218, 219, 220, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 240, 241, 243, 246, 247, 249, 250, 251, 253, 255, 257, 262, 263, 265, 267, 268, 269, 270, 271
			
			var indexCount: UInt32 = 6
			var indexOffset: UInt32 = 12
			
			@Count(givenBy: \Self.indexCount)
			@Offset(givenBy: \Self.indexOffset)
			var indices: [UInt32] // indices into btl_ai
								  // 29, 30, 39, 57, 81, 82, 84, 86,  88, 102, 110, 146, 148,      272, 273, 274
								  // 10, 17, 29, 30, 57, 81, 83, 85,  87,  89, 103, 111, 147, 149, 272, 273, 274
								  // 10, 17, 29, 30, 57, 81, 83, 85,  87,  89, 103, 111, 147, 149, 272, 273, 274
								  //  4, 23, 25, 81, 82, 84, 86, 88, 102, 110, 146, 148,           272, 273, 274
								  // 10, 23, 25, 81, 83, 85, 87, 89, 103, 111, 147, 149,           272, 273, 274
								  // 10, 23, 25, 81, 83, 85, 87, 89, 103, 111, 147, 149,           272, 273, 274
		}
	}
	
	struct Unpacked: Codable {}
}

// MARK: packed
extension AST.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: Carbonizer.Configuration) -> Self { self }
	
	func unpacked(configuration: Carbonizer.Configuration) -> AST.Unpacked {
		AST.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: AST.Unpacked, configuration: Carbonizer.Configuration) {
		todo()
	}
}

// MARK: unpacked
extension AST.Unpacked: ProprietaryFileData {
	static let fileExtension = ".ast.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: Carbonizer.Configuration) -> AST.Packed {
		AST.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Carbonizer.Configuration) -> Self { self }
	
	fileprivate init(_ packed: AST.Packed, configuration: Carbonizer.Configuration) {
		todo()
	}
}
