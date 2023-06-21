//
//  ConvertableFromData.swift
//  
//
//  Created by simon pellerin on 2023-06-16.
//

import Foundation

protocol ConvertableFromData: BinaryInteger {
	static var numberOfBytes: Int { get }
}

extension ConvertableFromData {
	init?(from data: Data) {
		guard data.count == Self.numberOfBytes else { return nil }
		
		var output = Self.zero
		
		for (index, byte) in data.enumerated() {
			output |= Self(byte) << Self(index * 8)
		}
		
		self.init(output)
	}
	
	var asData: Data {
		var output = Data()
		
		for index in 0 ..< Self.numberOfBytes {
			output.append(UInt8(truncatingIfNeeded: self >> (index * 8)))
		}
		
		return output
	}
}

extension UInt8: ConvertableFromData {
	static let numberOfBytes = 1
}

extension UInt16: ConvertableFromData {
	static let numberOfBytes = 2
}

extension UInt32: ConvertableFromData {
	static let numberOfBytes = 4
}

extension UInt64: ConvertableFromData {
	static let numberOfBytes = 8
}
