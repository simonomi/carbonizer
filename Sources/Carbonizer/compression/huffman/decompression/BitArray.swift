import BinaryParser

extension Huffman {
	struct BitArray: CustomDebugStringConvertible {
		var data: UInt32
		var count: Int
		
		init() {
			data = 0
			count = 0
		}
		
		private init(data: UInt32, count: Int) {
			self.data = data
			self.count = count
		}
		
		static let maxCount = 32
		
		mutating func append(_ bit: Bool) {
			precondition(count < Self.maxCount)
			count += 1
			if bit {
				data |= 1 << (Self.maxCount - count)
			}
		}
		
		mutating func prepend(_ bit: Bool) {
			precondition(count < Self.maxCount)
			count += 1
			data >>= 1
			if bit {
				data |= 1 << (Self.maxCount - 1)
			}
		}
		
		consuming func prepending(_ bit: Bool) -> Self {
			prepend(bit)
			return self
		}
		
		mutating func append(contentsOf other: Self) -> Self? {
			let overflow: Self?
			(self, overflow) = self + other
			return overflow
		}
		
		func write(to data: Datawriter) {
			data.write(self.data)
		}
		
		static func + (_ left: Self, _ right: Self) -> (Self, overflow: Self?) {
			if left.count + right.count <= maxCount {
				(
					Self(
						data: left.data | (right.data >> left.count),
						count: left.count + right.count
					),
					nil
				)
			} else {
				(
					Self(
						data: left.data | (right.data >> left.count),
						count: maxCount
					),
					Self(
						data: right.data << (maxCount - left.count),
						count: (right.count + left.count) - maxCount
					)
				)
			}
		}
		
		var debugDescription: String {
			if count == 0 {
				"[]"
			} else {
				"[" + (1...count)
					.map { Self.maxCount - $0 }
					.map { (data >> $0) & 1 }
					.map {
						if $0 == 0 {
							"0"
						} else {
							"1"
						}
					}
					.joined() + "]"
			}
		}
	}
}
