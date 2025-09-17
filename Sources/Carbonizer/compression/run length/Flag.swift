import BinaryParser

extension RunLength {
	struct Flag {
		var raw: Byte
		
		private static let compressionBit: Byte = 0b1000_0000
		private static let byteCountMask: Byte = ~compressionBit
		
		init(_ raw: Byte) {
			self.raw = raw
		}
		
		// TODO: should these have 'Count' in the name??
		init(compressedByteCount: Int) {
			raw = Self.compressionBit | Byte(compressedByteCount - 3)
		}
		
		init(uncompressedByteCount: Int) {
			raw = Byte(uncompressedByteCount - 1)
			precondition(!isCompressed, "tried to encode more than the maximum number of uncompressed bytes: \(uncompressedByteCount) (max \(maxUncompressedCount))")
		}
		
		var isCompressed: Bool {
			raw & Self.compressionBit != 0
		}
		
		var byteCount: Int {
			if isCompressed {
				Int(raw & Self.byteCountMask) + 3
			} else {
				Int(raw & Self.byteCountMask) + 1
			}
		}
		
		func write(to data: Datawriter) {
			data.write(raw)
		}
	}
}
