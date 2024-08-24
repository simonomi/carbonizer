import BinaryParser

struct OBJ<Scalar: SIMDScalar> {
	var vertices: [SIMD3<Scalar>]
	var textureVertices: [SIMD2<Scalar>]
//	var faces: [(SIMD3<Int>, texture: SIMD3<Int>)]
	var polygons: [Polygon]
	
	enum Polygon {
		case face(SIMD3<Int>, texture: SIMD3<Int>)
		case useTexture(String)
		
		var description: String {
			switch self {
				case .face(let vertices, let textures):
					"f \(vertices.x)/\(textures.x)/0 \(vertices.y)/\(textures.y)/0 \(vertices.z)/\(textures.z)/0"
				case .useTexture(let textureName):
					"usemtl \(textureName)"
			}
		}
	}
	
	init(
		vertices: [SIMD3<Scalar>],
		textureVertices: [SIMD2<Scalar>],
		polygons: [Polygon]
	) {
		self.vertices = vertices
		self.textureVertices = textureVertices
		self.polygons = polygons
	}
	
	init() {
		vertices = []
		textureVertices = []
		polygons = []
	}
	
	func text(mtlFile: String) -> String {
		let vertexListText = vertices
			.map { "v \($0.x) \($0.y) \($0.z)" }
			.joined(separator: "\n")
		
		let textureVertexListText = textureVertices
			.map { "vt \($0.x) \($0.y)" }
			.joined(separator: "\n")
		
		let faceListText = polygons
			.map(\.description)
			.joined(separator: "\n")
		
		return "mtllib \(mtlFile).mtl\n\n\(vertexListText)\n\n\(textureVertexListText)\n\n\(faceListText)"
	}
}
