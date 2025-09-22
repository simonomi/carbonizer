import BinaryParser

@BinaryConvertible
struct Vector3_2012 {
	var x: FixedPoint2012
	var y: FixedPoint2012
	var z: FixedPoint2012
	
	init(_ simd3: SIMD3<Double>) {
		x = FixedPoint2012(simd3.x)
		y = FixedPoint2012(simd3.y)
		z = FixedPoint2012(simd3.z)
	}
}

extension SIMD3<Double> {
	init(_ vector3_2012: Vector3_2012) {
		self.init(
			Double(vector3_2012.x),
			Double(vector3_2012.y),
			Double(vector3_2012.z)
		)
	}
}
