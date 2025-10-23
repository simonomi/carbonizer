extension String {
	enum Direction {
		case leading, trailing
	}
	
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
	
	init(withoutDecimalIfWhole number: some FloatingPoint & LosslessStringConvertible) {
		if number.truncatingRemainder(dividingBy: 1) == 0 {
			assert(String(number).suffix(2) == ".0")
			self = String(String(number).dropLast(2))
		} else {
			self = String(number)
		}
	}
}

extension DefaultStringInterpolation {
	mutating func appendInterpolation(_ number: some BinaryInteger, digits: Int) {
		precondition(number >= 0)
		appendInterpolation(String(number).padded(toLength: digits, with: "0"))
	}
}
