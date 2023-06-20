//
//  Metadata.swift
//
//
//  Created by simon pellerin on 2023-06-20.
//

import Foundation

extension MCMFile {
	struct Metadata {
		var standalone: Bool
		var compression: (CompressionType, CompressionType)
		var index: UInt16
		
		init?(from date: Date) {
			let data = Int(date.timeIntervalSince1970)
			
			let twentyFourBitLimit = 16777216
			guard data < twentyFourBitLimit else { return nil }
			
			let standaloneBit = data & 1
			let compression1Bits = data >> 1 & 0b11
			let compression2Bits = data >> 3 & 0b11
			let indexBits = data >> 5
			
			standalone = standaloneBit > 0
			
			guard let compression1 = CompressionType(rawValue: UInt8(compression1Bits)),
				  let compression2 = CompressionType(rawValue: UInt8(compression2Bits)) else { return nil }
			compression = (compression1, compression2)
			
			index = UInt16(indexBits)
		}
	}
}
