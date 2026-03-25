import BinaryParser

struct USD {
	var meshName: String
	var animationLength: Int?
	var mesh: USDMesh
	var skeleton: USDSkeleton?
	
	init(
		mesh: some Mesh,
		animationData: Animation.Unpacked?,
		modelName: String,
		texturePath: String,
		textureNames: [UInt32: String]?,
		texturesHaveTranslucency: [String: Bool]?
	) throws {
		meshName = modelName.replacing(" ", with: "_")
		
		// TOOD: is empty the right choice here? should it be one identity or smthn?
		let matrices = mesh.bones.map { $0.map(\.matrix) } ?? []
		
		let parsingResult = try parseCommands(
			mesh.gpuCommands(),
			worldRootBoneCount: mesh.worldRootBoneCount(),
			textureNames: textureNames?
				.mapValues { $0.replacingOccurrences(of: ".", with: "_") }
				.mapValues {
					if $0.starts(with: /[0-9]/) {
						"_" + $0
					} else {
						$0
					}
				},
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
		
		animationLength = (animationData?.animationLength).map { Int($0) }
		
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
			).map { [meshName] (index, materialName, faceIndices) in
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
							texturePath: texturePath,
							// if we're unsure, default to no, because it's easier to notice
							// if transparency is missing and add it than have to
							// remove it from a bunch of extra places
							hasTranslucency: texturesHaveTranslucency?[$0] ?? false
						)
					}
				)
			}
		)
		
		skeleton = mesh.bones.map { bones in
			USDSkeleton(
				meshName: meshName,
				boneNames: bones.map(\.name),
				restTransforms: matrices,
				animation: animationData?.keyframes.map {
					USDAnimation(
						boneNames: bones.map(\.name),
						transforms: $0
					)
				}
			)
		}
	}
	
	func string() -> String {
		let timeCodes = animationLength.map {
			"""
			startTimeCode = 0
			endTimeCode = \($0)
			timeCodesPerSecond = 60
			"""
		} ?? ""
		
		let skeleton = skeleton.map {
			$0.string()
		} ?? ""
		
		return """
			#usda 1.0
			(
				defaultPrim = "\(meshName)"
				metersPerUnit = 1
				upAxis = "Y"
				\(timeCodes.indented(by: 1))
			)
			
			def SkelRoot "\(meshName)" (
				purpose = "guide"
			) {
				\(self.mesh.string().indented(by: 1))
				
				\(skeleton.indented(by: 1))
			}
			"""
	}
}
