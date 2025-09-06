import Foundation

struct Metadata {
	var skipFile: Bool // 1 bit
	var standalone: Bool // 1 bit
	var compression: (MCM.Unpacked.CompressionType, MCM.Unpacked.CompressionType) // 2 bits, 2 bits
	var maxChunkSize: UInt32 // 4 bits, then multiplied by 4kB
	var index: UInt16 // 16 bits
	
	var huffmanCompressionInfo: [Huffman.CompressionInfo]
	
	init(
		skipFile: Bool,
		standalone: Bool,
		compression: (MCM.Unpacked.CompressionType, MCM.Unpacked.CompressionType),
		maxChunkSize: UInt32,
		index: UInt16,
		huffmanCompressionInfo: [Huffman.CompressionInfo]
	) {
		self.skipFile = skipFile
		self.standalone = standalone
		self.compression = compression
		self.maxChunkSize = maxChunkSize
		self.index = index
		self.huffmanCompressionInfo = huffmanCompressionInfo
	}
	
	init?(forItemAt path: URL) throws {
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
		
		let twentySixBitLimit = 67_108_864
		guard data < twentySixBitLimit else { return nil }
		
		let skipFileBit = data & 1
		let standaloneBit = data >> 1 & 1
		let compression1Bits = data >> 2 & 0b11
		let compression2Bits = data >> 4 & 0b11
		let maxChunkSizeBits = data >> 6 & 0b1111
		let indexBits = data >> 10
		
		skipFile = skipFileBit > 0
		
		standalone = standaloneBit > 0
		
		compression = (
			MCM.Unpacked.CompressionType(rawValue: UInt8(compression1Bits)) ?? .none,
			MCM.Unpacked.CompressionType(rawValue: UInt8(compression2Bits)) ?? .none
		)
		
		maxChunkSize = UInt32(maxChunkSizeBits) * 0x1000
		
		index = UInt16(indexBits)
		
		huffmanCompressionInfo = []
	}
	
	var asDate: Date {
		let skipFileBit: UInt32 = skipFile ? 1 : 0
		let standaloneBit: UInt32 = standalone ? 1 : 0
		let compression1Bits = UInt32(compression.0.rawValue)
		let compression2Bits = UInt32(compression.1.rawValue)
		let maxChunkSizeBits = maxChunkSize / 0x1000
		let indexBits = UInt32(index)
		
		let outputBits = skipFileBit | standaloneBit << 1 | compression1Bits << 2 | compression2Bits << 4 | maxChunkSizeBits << 6 | indexBits << 10
		return Date(timeIntervalSince1970: TimeInterval(outputBits))
	}
	
	func swizzled(_ body: (inout Self) -> Void) -> Self {
		var mutableSelf = self
		body(&mutableSelf)
		return mutableSelf
	}
	
	static let skipFile: Self = Metadata(skipFile: true, standalone: false, compression: (.none, .none), maxChunkSize: 0, index: 0, huffmanCompressionInfo: [])
}

extension Metadata: Codable {
	enum CodingKeys: CodingKey {
		case skipFile, standalone, firstCompressionType, secondCompressionType, maxChunkSize, index, huffmanCompressionInfo
	}
	
	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		skipFile = try container.decode(Bool.self, forKey: .skipFile)
		
		standalone = try container.decode(Bool.self, forKey: .standalone)
		
		compression = (
			try container.decode(MCM.Unpacked.CompressionType.self, forKey: .firstCompressionType),
			try container.decode(MCM.Unpacked.CompressionType.self, forKey: .secondCompressionType)
		)
		
		maxChunkSize = try container.decode(UInt32.self, forKey: .maxChunkSize)
		index = try container.decode(UInt16.self, forKey: .index)
		
		huffmanCompressionInfo = try container.decode([Huffman.CompressionInfo].self, forKey: .huffmanCompressionInfo)
	}
	
	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(skipFile,               forKey: .skipFile)
		try container.encode(standalone,             forKey: .standalone)
		try container.encode(compression.0,          forKey: .firstCompressionType)
		try container.encode(compression.1,          forKey: .secondCompressionType)
		try container.encode(maxChunkSize,           forKey: .maxChunkSize)
		try container.encode(index,                  forKey: .index)
		try container.encode(huffmanCompressionInfo, forKey: .huffmanCompressionInfo)
	}
}
