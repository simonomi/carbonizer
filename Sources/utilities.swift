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
}

extension Collection {
	/// Returns the element at the specified index if it is within bounds, otherwise nil.
	func element(at index: Index) -> Element? {
		indices.contains(index) ? self[index] : nil
	}
}

extension Sequence {
	func min<T: Comparable>(by keyPath: KeyPath<Element, T>) -> Element? {
		self.min { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
	}
	
	func max<T: Comparable>(by keyPath: KeyPath<Element, T>) -> Element? {
		self.max { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
	}
}

extension JSONEncoder {
	convenience init(_ formatting: OutputFormatting) {
		self.init()
		outputFormatting = formatting
	}
}
