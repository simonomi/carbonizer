enum RunLength {
	static let maxCompressedCount = Int(Byte.max) / 2 + 3
	static let maxUncompressedCount = Int(Byte.max) / 2 + 1
}
