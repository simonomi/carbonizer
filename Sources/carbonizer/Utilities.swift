//
//  Utilities.swift
//
//
//  Created by alice on 2023-11-25.
//

import Foundation

extension URL {
	static func fromFilePath(_ filePath: String) -> URL {
		URL(filePath: filePath)
	}
}

func createOffsets(start: UInt32, sizes: [UInt32]) -> [UInt32] {
	sizes
		.dropLast()
		.reduce(into: [start]) { offsets, size in
			offsets.append(offsets.last! + size)
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
}
