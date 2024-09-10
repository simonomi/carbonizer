struct Matrix4x3<Scalar: SIMDScalar> {
	var x: SIMD3<Scalar>
	var y: SIMD3<Scalar>
	var z: SIMD3<Scalar>
	var transform: SIMD3<Scalar>
}

extension Matrix4x3<Double> {
	init(_ matrix4x3_2012: Matrix4x3_2012) {
		x = SIMD3(matrix4x3_2012.x)
		y = SIMD3(matrix4x3_2012.y)
		z = SIMD3(matrix4x3_2012.z)
		transform = SIMD3(matrix4x3_2012.transform)
	}
}

extension Matrix4x3 where Scalar: FloatingPoint & ExpressibleByFloatLiteral {
	static var identity: Self {
		Self(
			x: SIMD3(1, 0, 0),
			y: SIMD3(0, 1, 0),
			z: SIMD3(0, 0, 1),
			transform: .zero
		)
	}
	
	func as4x4Array() -> [Scalar] {
		[
			x.x, y.x, z.x, transform.x,
			x.y, y.y, z.y, transform.y,
			x.z, y.z, z.z, transform.z,
			0, 0, 0, 1
		]
	}
	
	func asProper4x4Array() -> [Scalar] {
		[
			x.x, x.y, x.z, transform.x,
			y.x, y.y, y.z, transform.y,
			z.x, z.y, z.z, transform.z,
			0, 0, 0, 1
		]
	}
	
	func badInverse() -> Self {
		Self(
			x: SIMD3(1, 0, 0),
			y: SIMD3(0, 1, 0),
			z: SIMD3(0, 0, 1),
			transform: -transform
		)
	}
	
	func inverse() -> Self? {
		let temp0 = det_sub_proc(1, 2, 3)
		let determinant = temp0.dot(SIMD4(x.x, y.x, z.x, transform.x)) // top row of things
		
		guard determinant != .zero else { return nil }
		
		let inverseDeterminant = 1 / determinant
		
		let realTemp0 = temp0 * inverseDeterminant
		let temp1 = det_sub_proc(0, 3, 2) * inverseDeterminant
		let temp2 = det_sub_proc(0, 1, 3) * inverseDeterminant
//		let temp3 = det_sub_proc(0, 2, 1) * inverseDeterminant
		
		return Self(
			x: SIMD3(realTemp0.x, temp1.x, temp2.x),
			y: SIMD3(realTemp0.y, temp1.y, temp2.y),
			z: SIMD3(realTemp0.z, temp1.z, temp2.z),
			transform: SIMD3(realTemp0.w, temp1.w, temp2.w)
		)
	}
	
	func det_sub_proc(_ x: Int, _ y: Int, _ z: Int) -> SIMD4<Scalar> {
		let array = as4x4Array()
		
		let a = SIMD4(array[x + 4],  array[x + 12], array[x + 0],  array[x + 8])
		let b = SIMD4(array[y + 8],  array[y + 8],  array[y + 4],  array[y + 4])
		let c = SIMD4(array[z + 12], array[z + 0],  array[z + 12], array[z + 0])
		
		let d = SIMD4(array[x + 8],  array[x + 8],  array[x + 4],  array[x + 4])
		let e = SIMD4(array[y + 12], array[y + 0],  array[y + 12], array[y + 0])
		let f = SIMD4(array[z + 4],  array[z + 12], array[z + 0],  array[z + 8])
		
		let g = SIMD4(array[x + 12], array[x + 0],  array[x + 12], array[x + 0])
		let h = SIMD4(array[y + 4],  array[y + 12], array[y + 0],  array[y + 8])
		let i = SIMD4(array[z + 8],  array[z + 8],  array[z + 4],  array[z + 4])
		
		var temp = a * b * c
		temp += d * e * f
		temp += g * h * i
		temp -= a * e * i
		temp -= d * h * c
		temp -= g * b * f
		
		return temp
	}
}

extension SIMD4 where Scalar: FloatingPoint {
	func dot(_ other: Self) -> Scalar {
		(self * other).sum()
	}
}
