enum RunLength {
	static let minCompressedCount = 3
	static let maxCompressedCount = Int(Flag.byteCountMask) + minCompressedCount
	
	// *should* be +1, but ff1 doesn't do that
	static let maxUncompressedCount = Int(Flag.byteCountMask) // + 1
}
