import BinaryParser

struct CompressionHeader: BinaryConvertible {
	var dataSize: UInt8 // 4 bits, 0 unless huffman
	var type: CompressionType // 4 bits
	var decompressedSize: UInt32 // 24 bits
	
	enum CompressionType: UInt8 {
		case none, lzss, huffman, runLength
	}
	
	init(_ data: Datastream) throws {
		let word = try data.read(UInt32.self)
		
		dataSize = UInt8(word & 0b1111)
		
		let typeBits = UInt8(word >> 4 & 0b1111)
		type = CompressionType(rawValue: typeBits) ?? .none
		
		decompressedSize = word >> 8
	}
	
	func write(to data: Datawriter) {
		data.write(
			UInt32(dataSize) |
			UInt32(type.rawValue << 4) |
			decompressedSize << 8
		)
	}
}
