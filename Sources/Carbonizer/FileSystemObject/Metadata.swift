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
	
	init?(forFileAt path: URL) throws {
		if let metadata = try path
			.getCreationDate()
			.flatMap(Self.init)
		{
			self = metadata
			return
		}
		
		let metadataPath = path
			.deletingPathExtension()
			.appendingPathExtension("metadata")
		
		if metadataPath.exists() {
			let rawMetadata = try Data(contentsOf: metadataPath)
			self = try JSONDecoder().decode(Self.self, from: rawMetadata)
			return
		}
		
		return nil
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

extension Metadata: Codable {
	enum CodingKeys: CodingKey {
		case standalone, firstCompressionType, secondCompressionType, maxChunkSize, index
	}
	
	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		standalone = try container.decode(Bool.self, forKey: .standalone)
		
		compression = (
			try container.decode(MCM.CompressionType.self, forKey: .firstCompressionType),
			try container.decode(MCM.CompressionType.self, forKey: .secondCompressionType)
		)
		
		maxChunkSize = try container.decode(UInt32.self, forKey: .maxChunkSize)
		index = try container.decode(UInt16.self, forKey: .index)
	}
	
	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(standalone,    forKey: .standalone)
		try container.encode(compression.0, forKey: .firstCompressionType)
		try container.encode(compression.1, forKey: .secondCompressionType)
		try container.encode(maxChunkSize,  forKey: .maxChunkSize)
		try container.encode(index,         forKey: .index)
	}
}
