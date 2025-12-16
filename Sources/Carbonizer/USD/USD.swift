//import OpenUSD
import BinaryParser

struct USD {
	var meshes: [USDMesh]
	
	init(
		mesh: Mesh.Unpacked,
		animationData: Animation.Unpacked,
		modelName: String, // TODO: never used
		texturePath: String,
		textureNames: [UInt32: String]?
	) throws {
		let matrices = mesh.bones.map(\.matrix)
		
		let parsingResult = try parseCommands(
			mesh.commands,
			textureNames: textureNames,
			matrices: matrices
		)
		
		meshes = parsingResult.polygons.enumerated().map { (index, materialAndPolygons) in
			let (materialName, polygons) = materialAndPolygons
			
			let meshName = materialName ?? "mesh\(index)"
			
			return USDMesh(
				name: meshName,
				vertices: parsingResult.vertices.map(\.0),
				textureVertices: polygons
					.flatMap {
						$0.map {
							$0.textureInfo.map {
								parsingResult.textureVertices[$0.textureVertexIndex]
							} ?? SIMD2(-1, -1)
						}
					},
				faceVertexIndices: polygons.recursiveMap(\.vertexIndex),
				faceVertexCounts: polygons.map(\.count),
				jointIndices: polygons.flatMap { $0 }.map { // TODO: is this right?
					parsingResult.vertices[$0.vertexIndex].bone
				},
				jointWeights: Array(repeating: 1, count: polygons.count),
				material: materialName.map {
					USDMaterial(
						name: $0,
						meshName: meshName,
						texturePath: texturePath
					)
				},
				skeleton: USDSkeleton(
					meshName: meshName,
					boneNames: mesh.bones.map(\.name),
					restTransforms: mesh.bones.map(\.matrix),
					animation: USDAnimation(
						boneNames: mesh.bones.map(\.name)
					)
				)
			)
		}
	}
	
	func string() -> String {
		"""
		#usda 1.0
		(
			defaultPrim = "root"
			metersPerUnit = 1
			upAxis = "Y"
		)
		
		def SkelRoot "root" {
			\(meshes.map { $0.string().indented(by: 1) }.joined(separator: "\n\t\n\t"))
		}
		"""
	}
}
