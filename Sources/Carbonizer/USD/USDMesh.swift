struct USDMesh {
	var name: String
	var vertices: [SIMD3<Double>]
//	var normals: [SIMD3<Double>]
	var textureVertices: [SIMD2<Double>]
	var faceVertexIndices: [[Int]]
	var faceVertexCounts: [Int]
	var jointIndices: [Int]
	var jointWeights: [Int]
	
	var material: USDMaterial?
	var skeleton: USDSkeleton
	
	func string() -> String {
		let materialBinding = if material != nil {
				"rel material:binding = </root/\(name)/material>"
			} else {
				""
			}
		
		let materialDefinition = material.map {
			$0.string().indented(by: 1)
		} ?? ""
		
		return """
			def Mesh "\(name)" (
				prepend apiSchemas = ["MaterialBindingAPI", "SkelBindingAPI"]
			) {
				point3f[] points = \(vertices.map { ($0.x, $0.y, $0.z) })
				
			//	normal3f[] normals = TODO (
			//		interpolation = "faceVarying"
			//	)
				
				texCoord2f[] primvars:st = \(textureVertices.map { ($0.x, $0.y) }) (
					interpolation = "faceVarying"
				)
				
				int[] faceVertexIndices = \(faceVertexIndices.flatMap { $0 })
				
				int[] faceVertexCounts = \(faceVertexCounts)
				
				int[] primvars:skel:jointIndices = \(jointIndices) (
					interpolation = "vertex"
				)
				
				float[] primvars:skel:jointWeights = \(jointWeights) (
					interpolation = "vertex"
				)
				
				\(materialBinding)
				rel skel:skeleton = </root/\(name)/skeleton>
				
				\(materialDefinition)
				
				\(skeleton.string().indented(by: 1))
			}
			"""
	}
}
