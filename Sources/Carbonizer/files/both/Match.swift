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
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> Match.Unpacked {
		Match.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: Match.Unpacked, configuration: Configuration) {
		data = unpacked.data
	}
	
	init(_ data: inout Datastream, configuration: Configuration) throws {
		do {
			let dataCount = data.bytesInRange.count / (Element.bitWidth / 8)
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
	
	func packed(configuration: Configuration) -> Match.Packed {
		Match.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: Match.Packed, configuration: Configuration) {
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
