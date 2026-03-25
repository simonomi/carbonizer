import BinaryParser

enum TCN { // 3CN
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "3CN"
		var value: UInt32
	}
	
	struct Unpacked {
		var value: UInt32
	}
}

// MARK: packed
extension TCN.Packed: ProprietaryFileData {
	static let fileExtension = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> TCN.Unpacked {
		TCN.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: TCN.Unpacked, configuration: Configuration) {
		value = unpacked.value
	}
}

// MARK: unpacked
extension TCN.Unpacked: ProprietaryFileData {
	static let fileExtension = ".3cn.json"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> TCN.Packed {
		TCN.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: TCN.Packed, configuration: Configuration) {
		value = packed.value
	}
}

// MARK: unpacked codable
extension TCN.Unpacked: Codable {
	init(from decoder: Decoder) throws {
		value = try UInt32(from: decoder)
	}
	
	func encode(to encoder: Encoder) throws {
		try value.encode(to: encoder)
	}
}
