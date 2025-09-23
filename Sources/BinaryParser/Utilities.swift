public typealias Byte = UInt8

extension String {
	@usableFromInline
	enum Direction {
		case leading, trailing
	}
	
	@inlinable
	func padded(
		toLength targetLength: Int,
		with character: Character,
		from direction: Direction = .leading
	) -> Self {
		guard targetLength > count else { return self }
		let padding = String(repeating: character, count: targetLength - count)
		return switch direction {
			case .leading: padding + self
			case .trailing: self + padding
		}
	}
	
	init(almostFullyQualified type: Any.Type) {
		self = Self(reflecting: type)
			.replacingOccurrences(of: "carbonizer.", with: "")
			.replacingOccurrences(of: "Swift.", with: "")
			.replacing(#/Array<(.+)>/#) { "[\($0.output.1)]" }
	}
}

enum ANSIFontEffect: Int {
	case normal = 0
	case bold = 1
	case underline = 4
	case black = 30
	case red = 31
	case green = 32
	case yellow = 33
	case blue = 34
	case magenta = 35
	case cyan = 36
	case white = 37
	case blackBackground = 40
	case redBackground = 41
	case greenBackground = 42
	case yellowBackground = 43
	case blueBackground = 44
	case magentaBackground = 45
	case cyanBackground = 46
	case whiteBackground = 47
	case brightBlack = 90
	case brightRed = 91
	case brightGreen = 92
	case brightYellow = 93
	case brightBlue = 94
	case brightMagenta = 95
	case brightCyan = 96
	case brightWhite = 97
	case brightBlackBackground = 100
	case brightRedBackground = 101
	case brightGreenBackground = 102
	case brightYellowBackground = 103
	case brightBlueBackground = 104
	case brightMagentaBackground = 105
	case brightCyanBackground = 106
	case brightWhiteBackground = 107
}

extension DefaultStringInterpolation {
	mutating func appendInterpolation(_ fontEffects: ANSIFontEffect...) {
		let effects = fontEffects
			.map(\.rawValue)
			.map(String.init)
			.joined(separator: ";")
		appendInterpolation("\u{001B}[\(effects)m")
	}
}

@usableFromInline
func showInvalidUTF8(in bytes: some Sequence<UInt8>) -> String {
	bytes
		.compactMap(UnicodeScalar.init)
		.map(\.debugDescription)
		.map { $0.dropFirst().dropLast() }
		.joined()
}
