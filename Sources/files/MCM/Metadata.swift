//
//  Metadata.swift
//
//
//  Created by simon pellerin on 2023-06-20.
//

import Foundation

extension MCMFile {
	init(from file: File, with metadata: Metadata) {
		index = Int(metadata.index)
		compression = metadata.compression
		maxChunkSize = metadata.maxChunkSize
		content = file
	}
	
	func metadata(standalone: Bool) -> Metadata {
		Metadata(
			standalone: standalone, 
			compression: compression,
			maxChunkSize: maxChunkSize,
			index: UInt16(index)
		)
	}
	
	struct Metadata {
		var standalone: Bool // 1 bit
		var compression: (CompressionType, CompressionType) // 2 bits, 2 bits
		var maxChunkSize: UInt32 // 4 bits, then multiplied by 4kB
		var index: UInt16 // 16 bits
		
		init(standalone: Bool, compression: (CompressionType, CompressionType), maxChunkSize: UInt32, index: UInt16) {
			self.standalone = standalone
			self.compression = compression
			self.maxChunkSize = maxChunkSize
			self.index = index
		}
		
		init?(from date: Date) {
			let data = Int(date.timeIntervalSince1970)
			
			let twentyFiveBitLimit = 33554432
			guard data < twentyFiveBitLimit else { return nil }
			
			let standaloneBit = data & 1
			let compression1Bits = data >> 1 & 0b11
			let compression2Bits = data >> 3 & 0b11
			let maxChunkSizeBits = data >> 5 & 0b1111
			let indexBits = data >> 9
			
			standalone = standaloneBit > 0
			
			guard let compression1 = CompressionType(rawValue: UInt8(compression1Bits)),
				  let compression2 = CompressionType(rawValue: UInt8(compression2Bits)) else { return nil }
			compression = (compression1, compression2)
			
			maxChunkSize = UInt32(maxChunkSizeBits) * 0x1000
			
			index = UInt16(indexBits)
		}
		
		func asDate() -> Date {
			let standaloneBit = standalone ? 1 : UInt32.zero
			let compression1Bits = UInt32(compression.0.rawValue)
			let compression2Bits = UInt32(compression.1.rawValue)
			let maxChunkSizeBits = maxChunkSize / 0x1000
			let indexBits = UInt32(index)
			
			let outputBits = standaloneBit | compression1Bits << 1 | compression2Bits << 3 | maxChunkSizeBits << 5 | indexBits << 9
			return Date(timeIntervalSince1970: TimeInterval(outputBits))
		}
	}
}
