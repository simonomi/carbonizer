import BinaryParser

struct CompressionHeader: BinaryConvertible {
	var dataSize: UInt8 // 4 bits, 0 unless huffman
	var type: CompressionType // 4 bits
	var decompressedSize: UInt32 // 24 bits
	
	enum CompressionType: UInt8 {
		case lzss = 1, huffman, runLength
	}
	
	enum CompressionError: Error {
		case invalidCompressionType(UInt8)
	}
	
	init(dataSize: UInt8, type: CompressionType, decompressedSize: UInt32) {
		self.dataSize = dataSize
		self.type = type
		self.decompressedSize = decompressedSize
	}
	
	init(_ data: Datastream) throws {
		let word = try data.read(UInt32.self)
		
		dataSize = UInt8(word & 0b1111)
		
		let typeBits = UInt8(word >> 4 & 0b1111)
		guard let compressionType = CompressionType(rawValue: typeBits) else {
			throw CompressionError.invalidCompressionType(typeBits)
		}
		type = compressionType
		
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
