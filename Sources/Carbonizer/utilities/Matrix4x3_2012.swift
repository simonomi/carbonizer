import BinaryParser

@BinaryConvertible
struct Matrix4x3_2012 {
	var x: Vector3_2012
	var y: Vector3_2012
	var z: Vector3_2012
	var translation: Vector3_2012
}

extension Matrix4x3_2012 {
	init(_ matrix4x3: Matrix4x3<Double>) {
		x = Vector3_2012(matrix4x3.x)
		y = Vector3_2012(matrix4x3.y)
		z = Vector3_2012(matrix4x3.z)
		translation = Vector3_2012(matrix4x3.translation)
	}
}
