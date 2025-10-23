extension Range where Bound: AdditiveArithmetic {
	init(start: Bound, count: Bound) {
		self = start..<(start + count)
	}
}
