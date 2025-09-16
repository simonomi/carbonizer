import BinaryParser

// ff1-only
enum AIS {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "AIS"
		
		var someCount: UInt32
		var someOffset: UInt32 = 0xC
		
		@Count(givenBy: \Self.someCount)
		@Offset(givenBy: \Self.someOffset)
		var somes: [Some]
		
		@BinaryConvertible
		struct Some: CustomStringConvertible {
			var unknown1: UInt32 // 0, 1, 2, 3, 5, 7, 8, 9, 10, 11, 12, 17, 18, 19, 20, 21, 22, 23, 25, 26, 27, 28, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 47, 48, 49, 50, 51, 52, 54, 55, 56, 57, 58, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 91, 92, 93, 97, 98, 99, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 149, 150, 151
			var unknown2: UInt32 // 1, 2, 3, 5, 6, 7, 8, 10, 15, 16, 17, 18, 19, 20, 21, 22, 25, 28, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 55, 56, 57, 58, 59, 60, 61, 70, 75, 80, 99
			
			var description: String {
				"(\(unknown1), \(unknown2))"
			}
		}
	}
	
	struct Unpacked: Codable {}
}

// MARK: packed
extension AIS.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> AIS.Unpacked {
		AIS.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: AIS.Unpacked, configuration: CarbonizerConfiguration) {
		todo()
	}
}

// MARK: unpacked
extension AIS.Unpacked: ProprietaryFileData {
	static let fileExtension = ".ais.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> AIS.Packed {
		AIS.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: AIS.Packed, configuration: CarbonizerConfiguration) {
		todo()
	}
}
