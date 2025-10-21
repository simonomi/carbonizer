import BinaryParser

enum Palette {
	struct Packed: BinaryConvertible {
		var colors: [Color555]
		
		init(_ data: Datastream) throws {
			do {
				colors = try data.read([Color555].self, count: data.bytes.count / 2)
			} catch {
				throw BinaryParserError.whileReading(Self.self, error)
			}
		}
		
		func write(to data: Datawriter) {
			data.write(colors)
		}
	}
	
	struct Unpacked {
		var colors: [Color]
	}
}

extension Palette.Unpacked {
	/// replaces the first color with transparency
	func bmpColors() -> [BMP.Color] {
		var result = colors.map { BMP.Color($0) }
		
		result[0].replaceAlpha(with: 0)
		
		return result
	}
}

// MARK: packed
extension Palette.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> Palette.Unpacked {
		Palette.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: Palette.Unpacked, configuration: Configuration) {
		colors = unpacked.colors.map(Color555.init)
	}
}

// MARK: unpacked
extension Palette.Unpacked: ProprietaryFileData {
	static let fileExtension = ".imagePalette.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: Configuration) -> Palette.Packed {
		Palette.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: Palette.Packed, configuration: Configuration) {
		colors = packed.colors.map(Color.init)
	}
}

extension Palette.Unpacked: Codable {
	init(from decoder: any Decoder) throws {
		colors = try [Color](from: decoder)
	}
	
	func encode(to encoder: any Encoder) throws {
		try colors.encode(to: encoder)
	}
}
