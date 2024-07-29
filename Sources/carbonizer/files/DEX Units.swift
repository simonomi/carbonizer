protocol UnitProtocol {
	static func parse(_ text: Substring) -> Int32?
	static func format(_ number: Int32) -> String
}

protocol PrefixUnit: UnitProtocol {
	static var prefix: String { get }
}

extension PrefixUnit {
	static func parse(_ text: Substring) -> Int32? {
		text
			.split(whereSeparator: \.isWhitespace)
			.last
			.flatMap { Int32($0) }
	}
	
	static func format(_ number: Int32) -> String {
		"\(Self.prefix) \(number)"
	}
}

protocol SuffixUnit: UnitProtocol {
	static var suffix: String { get }
}

extension SuffixUnit {
	static func parse(_ text: Substring) -> Int32? {
		text
			.split(whereSeparator: \.isWhitespace)
			.first
			.flatMap { Int32($0) }
	}
	
	static func format(_ number: Int32) -> String {
		"\(number) \(Self.suffix)"
	}
}

enum DialogueUnit: PrefixUnit    { static let prefix = "dialogue"     }
enum EffectUnit: PrefixUnit      { static let prefix = "effect"       }
enum ImageUnit: PrefixUnit       { static let prefix = "image"        }
enum MapUnit: PrefixUnit         { static let prefix = "map"          }
enum MovementUnit: PrefixUnit    { static let prefix = "movement"     }
enum MusicUnit: PrefixUnit       { static let prefix = "music"        }
enum SoundEffectUnit: PrefixUnit { static let prefix = "sound effect" }

enum DegreeUnit: SuffixUnit      { static let suffix = "degrees"      }
enum FrameUnit: SuffixUnit       { static let suffix = "frames"       }

enum CharacterUnit: UnitProtocol {
	static func parse(_ text: Substring) -> Int32? {
		characterNames
			.first(where: { $0.value.caseInsensitiveEquals(text) })
			.map(\.key)
		?? text
			.split(separator: " ")
			.last
			.flatMap { Int32($0) }
	}
	
	static func format(_ number: Int32) -> String {
		"\(characterNames[number] ?? "character \(number)")"
	}
}

enum FossilUnit: UnitProtocol {
	static func parse(_ text: Substring) -> Int32? {
		fossilNames
			.first(where: { $0.value.caseInsensitiveEquals(text) })
			.map(\.key)
			.map(Int32.init)
		?? text
			.split(separator: " ")
			.last
			.flatMap { Int32($0) }
	}
	
	static func format(_ number: Int32) -> String {
		"\(fossilNames[Int(number)] ?? "fossil \(number)")"
	}
}

enum VivosaurUnit: UnitProtocol {
	static func parse(_ text: Substring) -> Int32? {
		vivosaurNames
			.firstIndex(where: text.caseInsensitiveEquals)
			.map(Int32.init)
		?? text
			.split(separator: " ")
			.last
			.flatMap { Int32($0) }
	}
	
	static func format(_ number: Int32) -> String {
		"\(vivosaurNames[safely: Int(number)] ?? "vivosaur \(number)")"
	}
}

enum FixedPointUnit: UnitProtocol {
	static func parse(_ text: Substring) -> Int32? {
		Double(text)
			.map { $0 * Double(1 << 12) }
			.map { Int32($0) }
	}
	
	static func format(_ number: Int32) -> String {
		let doubleApprox = Double(number) / Double(1 << 12)
//		let rescaled = doubleApprox * Double(1 << 12)
//		assert(Int32(rescaled) == number) // floating point should be a superset of 20.12 fixed point
		
		if let exactNumber = Int(exactly: doubleApprox) {
			return String(exactNumber)
		} else {
			return String(doubleApprox)
		}
	}
}

enum UnknownUnit: UnitProtocol {
	static func parse(_ text: Substring) -> Int32? {
		if text.contains("0x") {
			Int32(text.replacing("0x", with: ""), radix: 16)
		} else {
			Int32(text)
		}
	}
	
	static func format(_ number: Int32) -> String {
		if number.magnitude >= UInt16.max {
			hex(number)
		} else {
			String(number)
		}
	}
}
