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
