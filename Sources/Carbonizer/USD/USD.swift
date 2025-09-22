//import OpenUSD
//import BinaryParser
//
//struct USD {
//	let data: String
//	
//	init(
//		vertexData: VertexData.Packed,
//		animationData: AnimationData,
//		modelName: String,
//		textureNames: [UInt32: String]
//	) throws {
//		// copy so theres no side effects
//		let commandData = Datastream(vertexData.commands)
//		let commands = try commandData.readCommands()
//		
//		let matrices = vertexData.boneTable.bones
//			.map(\.matrix)
//			.map(Matrix4x3.init)
//		
//		let parsingResult = parseCommands(
//			commands,
//			textureNames: textureNames,
//			matrices: matrices
//		)
//		
//		let stage = Overlay.Dereference(pxr.UsdStage.CreateInMemory())
//		stage.SetMetadata(.UsdGeomTokens.metersPerUnit, pxr.VtValue(1))
//		stage.DefinePrim("/hello", .UsdGeomTokens.Xform)
//		
//		let prim = stage.DefinePrim("/hello/world", .UsdGeomTokens.Mesh)
//		let mesh = pxr.UsdGeomMesh(prim)
//		
//		
//		let points = parsingResult.vertices
//			.map(\.0)
//			.map { pxr.GfVec3f(Float($0.x), Float($0.y), Float($0.z)) }
//		
//		mesh.CreatePointsAttr(pxr.VtValue(pxr.VtVec3fArray(points)))
//		
//		
//		let vertexIndices = parsingResult.polygons
//			.flatMap(\.value)
//			.flatMap {
//				$0.map {
//					CInt($0.vertexIndex)
//				}
//			}
//		
//		mesh.CreateFaceVertexIndicesAttr(pxr.VtValue(pxr.VtIntArray(vertexIndices)))
//		
//		
//		let vertexCounts = parsingResult.polygons
//			.flatMap(\.value)
//			.map { CInt($0.count) }
//		
//		mesh.CreateFaceVertexCountsAttr(pxr.VtValue(pxr.VtIntArray(vertexCounts)))
//		
//		
//		let textureCoordinates = pxr.UsdGeomPrimvarsAPI(prim).CreatePrimvar(
//			"st",
//			pxr.SdfValueTypeName.TexCoord2fArray,
//			.UsdGeomTokens.faceVarying
//		)
//		
//		let textureVertices = parsingResult.polygons
//			.flatMap(\.value)
//			.flatMap {
//				$0.map {
//					$0.textureInfo.map {
//						parsingResult.textureVertices[$0.textureVertexIndex]
//					} ?? SIMD2(-1, -1)
//				}
//			}
//			.map { pxr.GfVec2f(Float($0.x), Float($0.y)) }
//		
//		
//		textureCoordinates.Set(pxr.VtVec2fArray(textureVertices), pxr.UsdTimeCode.Default())
//		
//		
//		let material = pxr.UsdShadeMaterial.Define(Overlay.TfWeakPtr(stage), "/hello/material")
//		
//		var stReader = pxr.UsdShadeShader.Define(Overlay.TfWeakPtr(stage), "/hello/material/stReader")
//		stReader.CreateIdAttr(pxr.VtValue("UsdPrimvarReader_float2" as pxr.TfToken))
//		stReader.CreateInput("varname", pxr.SdfValueTypeName.Token)
//			.Set(pxr.VtValue("st" as pxr.TfToken))
//		
//		var diffuseTextureSampler = pxr.UsdShadeShader.Define(Overlay.TfWeakPtr(stage), "/hello/material/diffuseTexture")
//		diffuseTextureSampler.CreateIdAttr(pxr.VtValue("UsdUVTexture" as pxr.TfToken))
//		diffuseTextureSampler.CreateInput("file", pxr.SdfValueTypeName.Asset)
//			.Set(pxr.VtValue("cha01a_01/cha01_b1.bmp" as pxr.SdfAssetPath))
//		diffuseTextureSampler.CreateInput("st", pxr.SdfValueTypeName.Float2)
//			.ConnectToSource(stReader.ConnectableAPI(), "result")
//		
//		var pbrShader = pxr.UsdShadeShader.Define(Overlay.TfWeakPtr(stage), "/hello/material/PBRShader")
//		pbrShader.CreateIdAttr(pxr.VtValue("UsdPreviewSurface" as pxr.TfToken))
//		pbrShader.CreateInput("diffuseColor", pxr.SdfValueTypeName.Color3f)
//			.ConnectToSource(diffuseTextureSampler.ConnectableAPI(), "rgb")
//		
//		material.CreateSurfaceOutput().ConnectToSource(pbrShader.ConnectableAPI(), "surface")
//		
//		pxr.UsdShadeMaterialBindingAPI(prim).Bind(material)
//		
//		
//		data = stage.ExportToString() ?? "nil"
//	}
//	
//	func string() -> String {
//		data
//	}
//}
