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
	
	func badInverse() -> Self {
		Self(
			x: SIMD3(1, 0, 0),
			y: SIMD3(0, 1, 0),
			z: SIMD3(0, 0, 1),
			transform: -transform
		)
	}
}

extension Matrix4x3<Double> {
	func inverse() -> Self? {
		let m = as4x4Array()
		var inv = Array(repeating: 0.0, count: 16)
		
		inv[0] = m[5]  * m[10] * m[15] -
		         m[5]  * m[11] * m[14] -
		         m[9]  * m[6]  * m[15] +
		         m[9]  * m[7]  * m[14] +
		         m[13] * m[6]  * m[11] -
		         m[13] * m[7]  * m[10]
		
		inv[4] = -m[4]  * m[10] * m[15] +
		          m[4]  * m[11] * m[14] +
		          m[8]  * m[6]  * m[15] -
		          m[8]  * m[7]  * m[14] -
		          m[12] * m[6]  * m[11] +
		          m[12] * m[7]  * m[10]
		
		inv[8] = m[4]  * m[9]  * m[15] -
		         m[4]  * m[11] * m[13] -
		         m[8]  * m[5]  * m[15] +
		         m[8]  * m[7]  * m[13] +
		         m[12] * m[5]  * m[11] -
		         m[12] * m[7]  * m[9]
		
		inv[12] = -m[4]  * m[9]  * m[14] +
		           m[4]  * m[10] * m[13] +
		           m[8]  * m[5]  * m[14] -
		           m[8]  * m[6]  * m[13] -
		           m[12] * m[5]  * m[10] +
		           m[12] * m[6]  * m[9]
		
		inv[1] = -m[1]  * m[10] * m[15] +
		          m[1]  * m[11] * m[14] +
		          m[9]  * m[2]  * m[15] -
		          m[9]  * m[3]  * m[14] -
		          m[13] * m[2]  * m[11] +
		          m[13] * m[3]  * m[10]
		
		inv[5] = m[0]  * m[10] * m[15] -
		         m[0]  * m[11] * m[14] -
		         m[8]  * m[2]  * m[15] +
		         m[8]  * m[3]  * m[14] +
		         m[12] * m[2]  * m[11] -
		         m[12] * m[3]  * m[10]
		
		inv[9] = -m[0]  * m[9]  * m[15] +
		          m[0]  * m[11] * m[13] +
		          m[8]  * m[1]  * m[15] -
		          m[8]  * m[3]  * m[13] -
		          m[12] * m[1]  * m[11] +
		          m[12] * m[3]  * m[9]
		
		inv[13] = m[0]  * m[9]  * m[14] -
		          m[0]  * m[10] * m[13] -
		          m[8]  * m[1]  * m[14] +
		          m[8]  * m[2]  * m[13] +
		          m[12] * m[1]  * m[10] -
		          m[12] * m[2]  * m[9]
		
		inv[2] = m[1]  * m[6] * m[15] -
				 m[1]  * m[7] * m[14] -
				 m[5]  * m[2] * m[15] +
				 m[5]  * m[3] * m[14] +
				 m[13] * m[2] * m[7] -
				 m[13] * m[3] * m[6]
		
		inv[6] = -m[0]  * m[6] * m[15] +
		          m[0]  * m[7] * m[14] +
		          m[4]  * m[2] * m[15] -
		          m[4]  * m[3] * m[14] -
		          m[12] * m[2] * m[7] +
		          m[12] * m[3] * m[6]
		
		inv[10] = m[0]  * m[5] * m[15] -
		          m[0]  * m[7] * m[13] -
		          m[4]  * m[1] * m[15] +
		          m[4]  * m[3] * m[13] +
		          m[12] * m[1] * m[7] -
		          m[12] * m[3] * m[5]
		
		inv[14] = -m[0]  * m[5] * m[14] +
		           m[0]  * m[6] * m[13] +
		           m[4]  * m[1] * m[14] -
		           m[4]  * m[2] * m[13] -
		           m[12] * m[1] * m[6] +
		           m[12] * m[2] * m[5]
		
		inv[3] = -m[1] * m[6] * m[11] +
		          m[1] * m[7] * m[10] +
		          m[5] * m[2] * m[11] -
		          m[5] * m[3] * m[10] -
		          m[9] * m[2] * m[7] +
		          m[9] * m[3] * m[6]
		
		inv[7] = m[0] * m[6] * m[11] -
				 m[0] * m[7] * m[10] -
				 m[4] * m[2] * m[11] +
				 m[4] * m[3] * m[10] +
				 m[8] * m[2] * m[7] -
				 m[8] * m[3] * m[6]
		
		inv[11] = -m[0] * m[5] * m[11] +
		           m[0] * m[7] * m[9] +
		           m[4] * m[1] * m[11] -
		           m[4] * m[3] * m[9] -
		           m[8] * m[1] * m[7] +
		           m[8] * m[3] * m[5]
		
		inv[15] = m[0] * m[5] * m[10] -
		          m[0] * m[6] * m[9] -
		          m[4] * m[1] * m[10] +
		          m[4] * m[2] * m[9] +
		          m[8] * m[1] * m[6] -
		          m[8] * m[2] * m[5]
		
		var det = m[0] * inv[0] + m[1] * inv[4] + m[2] * inv[8] + m[3] * inv[12]
		
		guard det != 0 else { return nil }
		
		det = 1.0 / det
		
		inv = inv.map { $0 * det }
		
		return Self(
			x: SIMD3(x: inv[0], y: inv[4], z: inv[8]),
			y: SIMD3(x: inv[1], y: inv[5], z: inv[9]),
			z: SIMD3(x: inv[2], y: inv[6], z: inv[10]),
			transform: SIMD3(x: inv[3], y: inv[7], z: inv[11])
		)
	}
}
