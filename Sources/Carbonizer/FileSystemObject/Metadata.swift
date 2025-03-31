import Foundation

struct Metadata {
	var standalone: Bool // 1 bit
	var compression: (MCM.CompressionType, MCM.CompressionType) // 2 bits, 2 bits
	var maxChunkSize: UInt32 // 4 bits, then multiplied by 4kB
	var index: UInt16 // 16 bits
	
	init(standalone: Bool, compression: (MCM.CompressionType, MCM.CompressionType), maxChunkSize: UInt32, index: UInt16) {
		self.standalone = standalone
		self.compression = compression
		self.maxChunkSize = maxChunkSize
		self.index = index
	}
	
	init?(_ date: Date) {
		let data = Int(date.timeIntervalSince1970)
		
		let twentyFiveBitLimit = 33554432
		guard data < twentyFiveBitLimit else { return nil }
		
		let standaloneBit = data & 1
		let compression1Bits = data >> 1 & 0b11
		let compression2Bits = data >> 3 & 0b11
		let maxChunkSizeBits = data >> 5 & 0b1111
		let indexBits = data >> 9
		
		standalone = standaloneBit > 0
		
		compression = (
			MCM.CompressionType(rawValue: UInt8(compression1Bits)) ?? .none,
			MCM.CompressionType(rawValue: UInt8(compression2Bits)) ?? .none
		)
		
		maxChunkSize = UInt32(maxChunkSizeBits) * 0x1000
		
		index = UInt16(indexBits)
	}
	
	var asDate: Date {
		let standaloneBit = standalone ? 1 : UInt32.zero
		let compression1Bits = UInt32(compression.0.rawValue)
		let compression2Bits = UInt32(compression.1.rawValue)
		let maxChunkSizeBits = maxChunkSize / 0x1000
		let indexBits = UInt32(index)
		
		let outputBits = standaloneBit | compression1Bits << 1 | compression2Bits << 3 | maxChunkSizeBits << 5 | indexBits << 9
		return Date(timeIntervalSince1970: TimeInterval(outputBits))
	}
	
	func swizzled(_ body: (inout Self) -> Void) -> Self {
		var mutableSelf = self
		body(&mutableSelf)
		return mutableSelf
	}
}
