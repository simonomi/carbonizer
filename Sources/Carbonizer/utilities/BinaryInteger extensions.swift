extension BinaryInteger {
	@inline(__always)
	var isEven: Bool {
		isMultiple(of: 2)
	}
	
	@inline(__always)
	var isOdd: Bool {
		!isMultiple(of: 2)
	}
	
	func roundedUpToTheNearest(_ value: Self) -> Self {
		if isMultiple(of: value) {
			self
		} else {
			self + (value - self % value)
		}
	}
}
