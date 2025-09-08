import BinaryParser

// region_center_match is weird, it might be u32s (and what abt the header??)

enum Match {
	struct Packed {
		var data: [UInt16]
	}
	
	struct Unpacked {
		var data: [UInt16]
	}
}

// MARK: packed
extension Match.Packed: ProprietaryFileData {
	static let fileExtension = "_match"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) -> Match.Unpacked {
		Match.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: Match.Unpacked, configuration: CarbonizerConfiguration) {
		data = unpacked.data
	}
	
	init(_ data: Datastream, configuration: CarbonizerConfiguration) throws {
		let dataCount = data.bytes[data.offset...].count / 2
		self.data = try data.read([UInt16].self, count: dataCount)
	}
	
	func write(to data: Datawriter) {
		data.write(self.data)
	}
}

// MARK: unpacked
extension Match.Unpacked: ProprietaryFileData {
	static let fileExtension = ".match.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: CarbonizerConfiguration) -> Match.Packed {
		Match.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) -> Self { self }
	
	fileprivate init(_ packed: Match.Packed, configuration: CarbonizerConfiguration) {
		data = packed.data
	}
}

extension Match.Unpacked: Codable {
	init(from decoder: any Decoder) throws {
		data = try [UInt16](from: decoder)
	}
	
	func encode(to encoder: any Encoder) throws {
		try data.encode(to: encoder)
	}
}
