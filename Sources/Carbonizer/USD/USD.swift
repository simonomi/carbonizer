import OpenUSD
import BinaryParser

struct USD {
	let data: String
	
	init(
		vertexData: VertexData,
		animationData: AnimationData,
		modelName: String,
		textureNames: [UInt32: String]
	) throws {
		// copy so theres no side effects
		let commandData = Datastream(vertexData.commands)
		let commands = try commandData.readCommands()
		
		let matrices = vertexData.boneTable.bones
			.map(\.matrix)
			.map(Matrix4x3.init)
		
		let parsingResult = parseCommands(
			commands,
			textureNames: textureNames,
			matrices: matrices
		)
		
		let stage = Overlay.Dereference(pxr.UsdStage.CreateInMemory())
		stage.DefinePrim("/hello", .UsdGeomTokens.Xform)
		
		// may fail?
		let mesh = pxr.UsdGeomMesh(stage.DefinePrim("/hello/world", .UsdGeomTokens.Mesh))
		
//		let points = [0, 1].flatMap { x in
//			[0, 1].flatMap { y in
//				[0, 1].map { z in
//					pxr.GfVec3f(x, y, z)
//				}
//			}
//		}
		
		let points = parsingResult.vertices
			.map(\.0)
			.map { pxr.GfVec3f(Float($0.x), Float($0.y), Float($0.z)) }
		
		mesh.CreatePointsAttr(pxr.VtValue(pxr.VtVec3fArray(points)))
		
		
		let vertexIndices = parsingResult.polygons
			.flatMap(\.value)
			.flatMap {
				$0.map {
					CInt($0.vertexIndex)
				}
			}
		
		mesh.CreateFaceVertexIndicesAttr(pxr.VtValue(pxr.VtIntArray(vertexIndices)))
		
		
		let vertexCounts = parsingResult.polygons
			.flatMap(\.value)
			.map { CInt($0.count) }
		
		mesh.CreateFaceVertexCountsAttr(pxr.VtValue(pxr.VtIntArray(vertexCounts)))
		
		data = stage.ExportToString() ?? "nil"
	}
	
	func string() -> String {
		data
	}
}
