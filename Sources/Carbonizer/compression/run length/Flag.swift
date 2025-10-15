import BinaryParser

extension RunLength {
	struct Flag {
		var raw: UInt8
		
		static let compressionBit: UInt8 = 0b1000_0000
		static let byteCountMask: UInt8 = ~compressionBit
		
		init(_ raw: UInt8) {
			self.raw = raw
		}
		
		init(compressedByteCount: Int) {
			assert(compressedByteCount >= minCompressedCount, "tried to encode fewer than the minimum number of compressed bytes: \(compressedByteCount) (min \(minCompressedCount)")
			raw = Self.compressionBit | UInt8(compressedByteCount - minCompressedCount)
		}
		
		init(uncompressedByteCount: Int) {
			raw = UInt8(uncompressedByteCount - 1)
			assert(!isCompressed, "tried to encode more than the maximum number of uncompressed bytes: \(uncompressedByteCount) (max \(maxUncompressedCount))")
		}
		
		var isCompressed: Bool {
			raw & Self.compressionBit != 0
		}
		
		var byteCount: Int {
			if isCompressed {
				Int(raw & Self.byteCountMask) + minCompressedCount
			} else {
				Int(raw & Self.byteCountMask) + 1
			}
		}
		
		func write(to data: Datawriter) {
			data.write(raw)
		}
	}
}
