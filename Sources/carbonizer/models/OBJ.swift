import BinaryParser

struct OBJ<Scalar: SIMDScalar> {
	var vertices: [SIMD3<Scalar>]
	var faces: [SIMD3<Int>]
	
	func text() -> String {
		let vertexListText = vertices
			.map { "v \($0.x) \($0.y) \($0.z)" }
			.joined(separator: "\n")
		
		let faceListText = faces
			.map { "f \($0.x) \($0.y) \($0.z)" }
			.joined(separator: "\n")
		
		return vertexListText + "\n\n" + faceListText
	}
}
