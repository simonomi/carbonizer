//
//  utilities.swift
//  
//
//  Created by simon pellerin on 2023-06-15.
//

import Foundation

extension FileManager {
	func contentsOfDirectory(at url: URL) throws -> [URL] {
		try contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
	}
	
	enum FileType {
		case file, folder, other
	}
	
	static func type(of file: URL) throws -> FileType {
		guard let typeString = try FileManager.default.attributesOfItem(atPath: file.path(percentEncoded: false))[.type] as? String else {
			return .other
		}
		
		switch typeString {
			case "NSFileTypeRegular":
				return .file
			case "NSFileTypeDirectory":
				return .folder
			default:
				return .other
		}
	}
}

extension Collection {
	/// Returns the element at the specified index if it is within bounds, otherwise nil.
	func element(at index: Index) -> Element? {
		indices.contains(index) ? self[index] : nil
	}
}

extension Sequence {
	func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
		sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
	}
	
	func min<T: Comparable>(by keyPath: KeyPath<Element, T>) -> Element? {
		self.min { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
	}
	
	func max<T: Comparable>(by keyPath: KeyPath<Element, T>) -> Element? {
		self.max { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
	}
}

extension Sequence where Element: AdditiveArithmetic {
	func sum() -> Element {
		reduce(.zero, +)
	}
}

extension Collection where Element: Equatable {
	func isAllTheSame() -> Bool {
		allSatisfy { $0 == first }
	}
}

extension JSONEncoder {
	convenience init(_ formatting: OutputFormatting) {
		self.init()
		outputFormatting = formatting
	}
}
