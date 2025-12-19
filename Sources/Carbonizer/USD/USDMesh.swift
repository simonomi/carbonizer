struct USDMesh {
	var name: String
	var vertices: [SIMD3<Double>]
//	var normals: [SIMD3<Double>]
	var textureVertices: [SIMD2<Double>]
	var faceVertexIndices: [[Int]]
	var jointIndices: [Int]
	
	var subsets: [USDSubset]
	
	func string() -> String {
		"""
		def Mesh "\(name)_mesh" (
			prepend apiSchemas = ["MaterialBindingAPI", "SkelBindingAPI"]
		) {
			uniform token[] xformOpOrder = ["!resetXformStack!"]
			
			point3f[] points = \(vertices.map { ($0.x, $0.y, $0.z) })
			
		//	normal3f[] normals = TODO (
		//		interpolation = "faceVarying"
		//	)
			
			texCoord2f[] primvars:st = \(textureVertices.map { ($0.x, $0.y) }) (
				interpolation = "faceVarying"
			)
			
			int[] faceVertexIndices = \(faceVertexIndices.flatMap { $0 })
			
			int[] faceVertexCounts = \(faceVertexIndices.map(\.count))
			
			int[] primvars:skel:jointIndices = \(jointIndices) (
				interpolation = "vertex"
			)
			
			float[] primvars:skel:jointWeights = \(Array(repeating: 1, count: jointIndices.count)) (
				interpolation = "vertex"
			)
			
			rel skel:skeleton = </\(name)/\(name)_mesh/\(name)_skeleton>
			
			uniform token subsetFamily:materialBind:familyType = "nonOverlapping"
			
			\(subsets.map { $0.string().indented(by: 1) }.joined(separator: "\n\t\n\t"))
		}
		"""
	}
}
