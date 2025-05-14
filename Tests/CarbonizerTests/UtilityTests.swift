import Testing

@testable import Carbonizer

@Test(arguments: [
	([2, 8, 9, 7, 3], [2, 5, 1], [2]),
	([2, 8, 9, 7, 3], [8, 2, 9], []),
	([2, 8, 9, 7, 3], [], []),
	([], [2, 8, 9, 7, 3], []),
	([130, 1, 0, 211, 130, 1, 0], [130, 1, 0], [130, 1, 0]),
	([1, 2, 3], [1, 2, 3], [1, 2, 3]),
])
func testCommonPrefix(_ first: [Int], _ second: [Int], _ expected: [Int]) {
	let commonPrefix = first.commonPrefix(with: second)
	
	#expect(first.starts(with: commonPrefix))
	#expect(second.starts(with: commonPrefix))
	
	#expect(commonPrefix.elementsEqual(expected))
}

typealias BitArray = Huffman.BitArray

extension BitArray: Equatable {
	public static func == (_ left: Self, _ right: Self) -> Bool {
		left.data == right.data && left.count == right.count
	}
}

func bitArray(for array: [Int]) -> BitArray {
	var result = BitArray()
	
	for bit in array {
		result.append(bit > 0)
	}
	
	return result
}

@Test(arguments: [
	(bitArray(for: [1, 0, 1]), bitArray(for: [0, 1, 0, 1]), (bitArray(for: [1, 0, 1, 0, 1, 0, 1]), nil)),
	(bitArray(for: [1, 1, 0, 0, 0]), bitArray(for: [0]), (bitArray(for: [1, 1, 0, 0, 0, 0]), nil)),
	(bitArray(for: [1, 1, 0, 0, 0]), bitArray(for: [0, 0, 0]), (bitArray(for: [1, 1, 0, 0, 0, 0, 0, 0]), nil)),
	(
		bitArray(for: [1, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0]),
		bitArray(for: [0]),
		(bitArray(for: [1, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0]), nil)
	),
	(
		bitArray(for: [1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0]),
		bitArray(for: [1, 1, 0, 0, 1, 1, 1, 0, 1, 1, 0, 1, 0, 0]),
		(
			bitArray(for: [1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0, 1, 1, 0, 1, 0]),
			bitArray(for: [0])
		)
	),
] as [(BitArray, BitArray, (BitArray, BitArray?))])
func bitArrayConcatination(
	_ first: BitArray,
	_ second: BitArray,
	_ expected: (BitArray, BitArray?)
) {
	#expect(first + second == expected)
}
