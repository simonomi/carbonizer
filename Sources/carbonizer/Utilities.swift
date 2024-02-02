import Foundation

extension URL {
	static func fromFilePath(_ filePath: String) -> URL {
		URL(filePath: filePath)
	}
}

func identity<T>(_ value: T) -> T { value }

/// pipe operator
//func |> <T, U>(lhs: T, rhs: (T) throws -> U) rethrows -> U {
//	try rhs(lhs)
//}

func createOffsets(start: UInt32, sizes: [UInt32], alignedTo alignment: UInt32 = 1) -> [UInt32] {
	sizes
		.dropLast()
		.reduce(into: [start]) { offsets, size in
			offsets.append((offsets.last! + size).roundedUpToTheNearest(alignment))
		}
}

func hex(_ value: some BinaryInteger) -> String {
	String(value, radix: 16)
}

extension BinaryInteger {
	func roundedUpToTheNearest(_ value: Self) -> Self {
		if isMultiple(of: value) {
			self
		} else {
			self + (value - self % value)
		}
	}
}

extension Sequence where Element: Sequence{
	func recursiveMap<T>(_ transform: @escaping (Element.Element) throws -> T) rethrows -> [[T]] {
		try map { try $0.map(transform) }
	}
}

extension Sequence where Element: AdditiveArithmetic {
	func sum() -> Element {
		reduce(.zero, +)
	}
}

extension Sequence {
	func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
		sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
	}
	
	func compactMap<T>(as type: T.Type) -> [T] {
		compactMap { $0 as? T }
	}
}

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
}

extension URL {
	func getCreationDate() throws -> Date? {
		try FileManager.default.attributesOfItem(atPath: path)[.creationDate] as? Date
	}
	
	func setCreationDate(to date: Date) throws {
		// TODO: wont work on windows
		try FileManager.default.setAttributes([.creationDate: date], ofItemAtPath: path(percentEncoded: false))
	}
	
	func contents() throws -> [URL] {
		try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil)
	}
	
	enum FileType {
		case file, folder, other(FileAttributeType?)
	}
	
	func type() throws -> FileType {
		let type = try FileManager.default.attributesOfItem(atPath: self.path(percentEncoded: false))[.type] as? FileAttributeType
		return switch type {
			case .some(.typeRegular): .file
			case .some(.typeDirectory): .folder
			default: .other(type)
		}
	}
}

extension JSONEncoder {
	convenience init(_ formatting: OutputFormatting...) {
		self.init()
		outputFormatting = OutputFormatting(formatting)
	}
}
