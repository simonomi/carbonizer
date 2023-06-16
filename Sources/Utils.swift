//
//  Utils.swift
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
