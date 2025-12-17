import BinaryParser

struct USD {
	var animationLength: Int
	var mesh: USDMesh
	
	init(
		mesh: Mesh.Unpacked,
		animationData: Animation.Unpacked,
		modelName: String,
		texturePath: String,
		textureNames: [UInt32: String]?
	) throws {
		let meshName = modelName.replacing(" ", with: "-")
		
		let matrices = mesh.bones.map(\.matrix)
		
		let parsingResult = try parseCommands(
			mesh.commands,
			textureNames: textureNames,
			matrices: matrices
		)
		
		// so that it's consistently in the same order
		let polygons = Array(parsingResult.polygons)
		
		// this is messy but i can't think of a more elegant way
		let faceIndices = polygons.map(\.value.count)
			.reduce(into: []) { partialResult, count in
				partialResult.append(
					Range(
						start: partialResult.last?.upperBound ?? 0,
						count: count
					)
				)
			}
		
		animationLength = Int(animationData.animationLength)
		
		self.mesh = USDMesh(
			name: meshName,
			vertices: parsingResult.vertices.map(\.0),
			textureVertices: polygons
				.flatMap(\.value)
				.flatMap {
					$0.map {
						$0.textureInfo.map {
							parsingResult.textureVertices[$0.textureVertexIndex]
						} ?? SIMD2(-1, -1)
					}
				},
			faceVertexIndices: polygons
				.flatMap(\.value)
				.recursiveMap(\.vertexIndex),
			jointIndices: parsingResult.vertices.map(\.bone),
			subsets: zip(
				0...,
				polygons.map(\.key),
				faceIndices
			).map { (index, materialName, faceIndices) in
				let subsetName = materialName ?? "subset\(index)"
				
				return USDSubset(
					name: subsetName,
					meshName: meshName,
					faceIndices: Array(faceIndices),
					material: materialName.map {
						USDMaterial(
							name: $0,
							meshName: meshName,
							subsetName: subsetName,
							texturePath: texturePath
						)
					}
				)
			},
			skeleton: USDSkeleton(
				meshName: meshName,
				boneNames: mesh.bones.map(\.name),
				restTransforms: matrices,
				animation: USDAnimation(
					boneNames: mesh.bones.map(\.name),
					transforms: animationData.keyframes
				)
			)
		)
	}
	
	func string() -> String {
		"""
		#usda 1.0
		(
			defaultPrim = "root"
			metersPerUnit = 1
			upAxis = "Y"
			startTimeCode = 0
			endTimeCode = \(animationLength)
			timeCodesPerSecond = 60
		)
		
		def SkelRoot "root" {
			\(mesh.string().indented(by: 1))
		}
		"""
	}
}
