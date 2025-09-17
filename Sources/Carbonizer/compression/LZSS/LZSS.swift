import BinaryParser

enum LZSS {
	static let minCompressedCount = 3
	static let maxCompressedCount = 0b1111 + minCompressedCount
	static let minDisplacement = 1
	static let maxDisplacement = 0b1111_1111_1111 + minDisplacement
}
