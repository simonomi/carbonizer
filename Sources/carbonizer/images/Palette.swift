import BinaryParser

@BinaryConvertible
struct RGB555Color {
	var raw: UInt16
	
	var red: Double {
		Double(raw & 0b11111) / 0b11111
	}
	
	var green: Double {
		Double(raw >> 5 & 0b11111) / 0b11111
	}
	
	var blue: Double {
		Double(raw >> 10 & 0b11111) / 0b11111
	}
}

struct Palette: BinaryConvertible {
	var colors: [RGB555Color]
	
	init(_ data: Datastream) throws {
		do {
			colors = try data.read([RGB555Color].self, count: data.bytes.count / 2)
		} catch {
			throw BinaryParserError.whileReading(Self.self, error)
		}
	}
	
	func write(to data: Datawriter) {
		data.write(colors)
	}
}
