import Foundation

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

@usableFromInline
func showInvalidUTF8(in bytes: some Sequence<UInt8>) -> String {
	bytes
		.compactMap(UnicodeScalar.init)
		.map(\.debugDescription)
		.map { $0.dropFirst().dropLast() }
		.joined()
}

extension Data {
	public init(_ datastream: Datastream) {
		self.init(datastream.bytesInRange)
	}
}
