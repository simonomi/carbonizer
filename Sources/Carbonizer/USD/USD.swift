//import OpenUSD
import BinaryParser

struct USD {
	let data: String
	
	init(
		mesh: Mesh.Unpacked,
		animationData: Animation.Unpacked,
		modelName: String,
		texturePath: String,
		textureNames: [UInt32: String]?
	) throws {
		let modelNameWithSpaces = modelName
		let modelName = modelName.replacing(" ", with: "-")
		
		let matrices = mesh.bones.map(\.matrix)
		
		let parsingResult = try parseCommands(
			mesh.commands,
			textureNames: textureNames,
			matrices: matrices
		)
		
		let points = parsingResult.vertices
			.map(\.0)
			.map { "(\($0.x), \($0.y), \($0.z))" }
			.joined(separator: ", ")
		
		let vertexIndices = parsingResult.polygons
			.flatMap(\.value)
			.flatMap {
				$0.map(\.vertexIndex)
			}
			.map(String.init)
			.joined(separator: ", ")
		
		let vertexCounts = parsingResult.polygons
			.flatMap(\.value)
			.map(\.count)
			.map(String.init)
			.joined(separator: ", ")
		
		let textureVertices = parsingResult.polygons
			.flatMap(\.value)
			.flatMap {
				$0.map {
					$0.textureInfo.map {
						parsingResult.textureVertices[$0.textureVertexIndex]
					} ?? SIMD2(-1, -1)
				}
			}
			.map { "(\($0.x), \($0.y))" }
			.joined(separator: ", ")
		
		// per material:
		// - mesh
		//   - vertices
		//   - texcoords (st)
		//   - faces vertex indices
		//   - face vertex counts
		//   - TODO: normals
		//   - joint indices
		//   - joint weights
		//   - material binding
		//   - skeleton binding
		//   - material
		//     - shader 1
		//     - shader 2
		//     - shader 3
		//   - skeleton
		//     - joints
		//     - bindTransforms
		//     - restTransforms?
		//     - animationSource
		//     - animation
		//       - joints
		//       - transforms timesamples
		
		data = """
			#usda 1.0
			
			def Xform "root" {
				def Mesh "mesh2" {
					rel material:binding = </root/_materials/Material>
					
					point3f[] points = [
						\(points)
					]
					
					texCoord2f[] primvar:st = [
						\(textureVertices)
					] (
						interpolation = "faceVarying"
					)
					
					int[] faceVertexCounts = [
						\(vertexCounts)
					]
					
					int[] faceVertexIndices = [
						\(vertexIndices)
					]
				}
			}
			"""
	}
	
	func string() -> String {
		data
	}
}
