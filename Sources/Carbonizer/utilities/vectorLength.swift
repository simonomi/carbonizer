extension SIMD3 where Scalar: FloatingPoint {
	func vectorLength() -> Scalar {
		(x * x + y * y + z * z).squareRoot()
	}
}
