import BinaryParser

extension LZSS {
	struct CompressedString {
		// count displacement
		//  0000_1111_1111_1111
		var firstByte: UInt8
		var secondByte: UInt8
		
		init(_ firstByte: UInt8, _ secondByte: UInt8) {
			self.firstByte = firstByte
			self.secondByte = secondByte
		}
		
		init(count: Int, displacement: Int) {
			precondition((minCompressedCount...maxCompressedCount).contains(count), "invalid count: \(count)")
			precondition((minDisplacement...maxDisplacement).contains(displacement), "invalid displacement: \(displacement)")
			
			let count = UInt8(count - minCompressedCount)
			
			let displacement = displacement - minDisplacement
			let disp = UInt8(displacement >> 8)
			let lacement = UInt8(displacement & 0b1111_1111)
			
			firstByte = (count << 4) | disp
			secondByte = lacement
		}
		
		var count: Int {
			Int(firstByte >> 4) + minCompressedCount
		}
		
		var displacement: Int {
			Int(firstByte & 0b1111) << 8 | Int(secondByte) + minDisplacement
		}
		
		func write(to data: Datawriter) {
			data.write(firstByte)
			data.write(secondByte)
		}
	}
}
