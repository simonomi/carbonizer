import BinaryParser

enum Match<Element: FixedWidthInteger & Codable> {
	struct Packed {
		var data: [Element]
	}
	
	struct Unpacked {
		var data: [Element]
	}
}

// MARK: packed
extension Match.Packed: ProprietaryFileData {
	static var fileExtension: String { "" }
	static var magicBytes: String { "" }
	static var packedStatus: PackedStatus { .packed }
	
	func packed(configuration: Carbonizer.Configuration) -> Self { self }
	
	func unpacked(configuration: Carbonizer.Configuration) -> Match.Unpacked {
		Match.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: Match.Unpacked, configuration: Carbonizer.Configuration) {
		data = unpacked.data
	}
	
	init(_ data: Datastream, configuration: Carbonizer.Configuration) throws {
		do {
			let dataCount = data.bytes[data.offset...].count / (Element.bitWidth / 8)
			self.data = try data.read([Element].self, count: dataCount)
		} catch {
			throw BinaryParserError.whileReading(Match.Packed.self, error)
		}
	}
	
	func write(to data: Datawriter) {
		data.write(self.data)
	}
}

// MARK: unpacked
extension Match.Unpacked: ProprietaryFileData {
	static var fileExtension: String { ".json" }
	static var magicBytes: String { "" }
	static var packedStatus: PackedStatus { .unpacked }
	
	func packed(configuration: Carbonizer.Configuration) -> Match.Packed {
		Match.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Carbonizer.Configuration) -> Self { self }
	
	fileprivate init(_ packed: Match.Packed, configuration: Carbonizer.Configuration) {
		data = packed.data
	}
}

extension Match.Unpacked: Codable {
	init(from decoder: any Decoder) throws {
		data = try [Element](from: decoder)
	}
	
	func encode(to encoder: any Encoder) throws {
		try data.encode(to: encoder)
	}
}
