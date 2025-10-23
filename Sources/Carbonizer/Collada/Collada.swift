struct Collada {
	var body: [XMLNode]
	
	func asString() -> String {
		let xmlHeader = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
		let collada: XMLNode = .collada(body)
		
		return xmlHeader + "\n" + collada.asString()
	}
}

fileprivate extension String {
	func withoutSpaces() -> Self {
		self.replacing(" ", with: "-")
	}
}

extension Collada {
	/// - Parameters:
	///   - texturePath: assets/mar name/texture index
	///   - textureNames: a mapping from palette offset to texture file name. the offset should be normalized (bit shifted according to type)
	init(
		mesh: Mesh.Unpacked,
		animationData: Animation.Unpacked,
		modelName: String,
		texturePath: String,
		textureNames: [UInt32: String]?
	) throws {
		let modelNameWithSpaces = modelName
		let modelName = modelName.withoutSpaces()
		
		let matrices = mesh.bones.map(\.matrix)
		
		let parsingResult = try parseCommands(
			mesh.commands,
			textureNames: textureNames,
			matrices: matrices
		)
		
		let boneCount = mesh.bones.count
		let boneNames = mesh.bones.map(\.name)
		
		precondition(boneCount > 0)
		
		let materialNames = parsingResult.materials.sorted()
		
		let materials: [XMLNode] = materialNames
			.map { materialName in
				.material(
					id: materialName,
					.instance_effect(effectId: "\(materialName)-effect")
				)
			}
		
		let effects: [XMLNode] = materialNames
			.map { materialName in
				.effect(
					id: "\(materialName)-effect",
					.profile_COMMON(
						.image( // TODO: move to library_images?
							id: "\(materialName)-image",
							.init_from("\(texturePath)/\(materialName).bmp")
						),
						.technique(
							sid: "technique",
							.newparam(
								sid: "surface",
								.surface(
									type: "2D",
									.init_from("\(materialName)-image")
								)
							),
							.newparam(
								sid: "sampler",
								.sampler2D(
									.source("surface")
								)
							),
							.lambert(
								.diffuse(
									// TODO: change texcoord per material?
									.texture(texture: "sampler", texcoord: "UVMap")
								),
								.index_of_refraction(0)
							)
						)
					)
				)
			}
		
		let polylists: [XMLNode] = parsingResult.polygons
			.sorted { left, right in
				if let left = left.key, let right = right.key {
					left < right
				} else {
					left.key == nil
				}
			}
			.map { (materialName, polygons) in
				if let materialName {
					.polylist(
						count: polygons.count,
						material: materialName,
						.input(semantic: "VERTEX", sourceId: "\(modelName)-vertices", offset: 0),
						.input(semantic: "TEXCOORD", sourceId: "\(modelName)-texture-coords", offset: 1),
						.vcount(polygons.map(\.count)),
						.p(Array(polygons.joined().flatMap { [$0.vertexIndex, $0.textureInfo!.textureVertexIndex] }))
					)
				} else {
					.polylist(
						count: polygons.count,
						.input(semantic: "VERTEX", sourceId: "\(modelName)-vertices", offset: 0),
						.vcount(polygons.map(\.count)),
						.p(Array(polygons.joined().map { $0.vertexIndex }))
					)
				}
			}
		
		let instanceMaterials: [XMLNode] = materialNames
			.map { materialName in
				.instance_material(
					symbol: materialName,
					target: materialName,
					.bind_vertex_input(semantic: "UVMap", input_semantic: "TEXCOORD")
				)
			}
		
		precondition(animationData.keyframes[0].count == boneCount, "the number of bones in the animation doesn't match the mesh")
		
		let transforms = animationData.keyframes.transposed()
		
		// this can differ from animationData.keyFrameCount, but it's *always* <=, so use it
		// if it's different, it's usually 1, except in o09warp1_01 for some reason
		let frameCount = Int(animationData.keyframes.count)
		
		precondition(boneCount == transforms.count)
		
		let transformSources: [XMLNode] = zip(boneNames, transforms)
			.map { (boneName, transforms) in
				.source(
					id: "\(modelName)-animation-\(boneName)-keyframes",
					.float_array(
						id: "\(modelName)-animation-\(boneName)-keyframes-array",
						transforms.flatMap { $0.as4x4Array() }
					),
					.technique_common(
						.accessor(
							sourceId: "\(modelName)-animation-\(boneName)-keyframes-array",
							count: transforms.count,
							stride: 16,
							.param(name: "TRANSFORM", type: "float4x4")
						)
					)
				)
			}
		
		let keyframeTimestamps = (0..<frameCount)
			.map(Double.init)
			.map { $0 * (1 / 60) } // play everything at 30fps for now
		
		let commonSamplers: [XMLNode] = [
			.source(
				id: "\(modelName)-animation-timestamps",
				.float_array(
					id: "\(modelName)-animation-timestamps-array",
					keyframeTimestamps
				),
				.technique_common(
					.accessor(
						sourceId: "\(modelName)-animation-timestamps-array",
						count: frameCount,
						.param(name: "TIME", type: "float")
					)
				)
			),
			.source(
				id: "\(modelName)-animation-interpolation",
				.name_array(
					id: "\(modelName)-animation-interpolation-array",
					Array(repeating: "STEP", count: frameCount)
				),
				.technique_common(
					.accessor(
						sourceId: "\(modelName)-animation-interpolation-array",
						count: frameCount,
						.param(name: "INTERPOLATION", type: "name")
					)
				)
			)
		]
		
		let samplers: [XMLNode] = boneNames.map { boneName in
			.sampler(
				id: "\(modelName)-animation-\(boneName)-sampler",
				.input(semantic: "INPUT", sourceId: "\(modelName)-animation-timestamps"),
				.input(semantic: "OUTPUT", sourceId: "\(modelName)-animation-\(boneName)-keyframes"),
				.input(semantic: "INTERPOLATION", sourceId: "animation-interpolation")
			)
		}
		
		let channels: [XMLNode] = boneNames.map { boneName in
			.channel(sourceId: "\(modelName)-animation-\(boneName)-sampler", target: "\(modelName)-skeleton/\(boneName)/transform")
		}
		
		let animation: XMLNode = .animation(
			transformSources + commonSamplers + samplers + channels
		)
		
		struct ColladaError: Error {
			var description: String
		}
		
		body = [
			.asset(
				.created(.now),
				.modified(.now)
			),
			.library_materials(materials),
			.library_effects(effects),
			.library_geometries(
				.geometry(
					id: "\(modelName)-mesh",
					.mesh(
						[
							.source(
								id: "\(modelName)-vertices-source",
								.float_array(
									id: "\(modelName)-vertices-array",
									parsingResult.vertices.map(\.0).flatMap {[ $0.x, $0.y, $0.z ]}
								),
								.technique_common(
									.accessor(
										sourceId: "\(modelName)-vertices-array",
										count: parsingResult.vertices.count,
										stride: 3,
										.param(name: "X", type: "float"),
										.param(name: "Y", type: "float"),
										.param(name: "Z", type: "float")
									)
								)
							),
							.source(
								id: "\(modelName)-texture-coords",
								.float_array(
									id: "\(modelName)-texture-coords-array",
									parsingResult.textureVertices.flatMap { [$0.x, $0.y] }
								),
								.technique_common(
									.accessor(
										sourceId: "\(modelName)-texture-coords-array",
										count: parsingResult.textureVertices.count,
										stride: 2,
										.param(name: "S", type: "float"),
										.param(name: "T", type: "float")
									)
								)
							),
							.vertices(
								id: "\(modelName)-vertices",
								.input(semantic: "POSITION", sourceId: "\(modelName)-vertices-source")
							)
						] + polylists
					)
				)
			),
			.library_controllers(
				.controller(
					id: "\(modelName)-controller",
					.skin(
						sourceId: "\(modelName)-mesh",
						.source(
							id: "\(modelName)-joints",
							.name_array(
								id: "\(modelName)-joints-array",
								boneNames
							),
							.technique_common(
								.accessor(
									sourceId: "\(modelName)-joints-array",
									count: boneCount,
									.param(name: "JOINT", type: "name")
								)
							)
						),
						.source(
							id: "\(modelName)-weights",
							.float_array(
								id: "\(modelName)-weights-array",
								Array(repeating: 1, count: boneCount) // TODO: document
							),
							.technique_common(
								.accessor(
									sourceId: "\(modelName)-weights-array",
									count: boneCount,
									.param(name: "WEIGHT", type: "float")
								)
							)
						),
						.source(
							id: "\(modelName)-inverse-bind-matrix",
							.float_array(
								id: "\(modelName)-inverse-bind-matrix-array",
								try matrices
									.map {
										guard let inverse = $0.inverse() else {
											throw ColladaError(description: "inverse failed")
										}
										return inverse
									}
									.flatMap { $0.as4x4Array() }
							),
							.technique_common(
								.accessor(
									sourceId: "\(modelName)-inverse-bind-matrix-array",
									count: boneCount,
									stride: 16,
									.param(name: "TRANSFORM", type: "float4x4")
								)
							)
						),
						.joints(
							.input(semantic: "JOINT", sourceId: "\(modelName)-joints"),
							.input(semantic: "INV_BIND_MATRIX", sourceId: "\(modelName)-inverse-bind-matrix")
						),
						.vertex_weights(
							count: parsingResult.vertices.count,
							.input(semantic: "JOINT", sourceId: "\(modelName)-joints", offset: 0),
							.input(semantic: "WEIGHT", sourceId: "\(modelName)-weights", offset: 0),
							.vcount(Array(repeating: 1, count: parsingResult.vertices.count)),
							.v(parsingResult.vertices.map(\.bone))
						)
					)
				)
			),
			.library_animations(animation),
			.library_visual_scenes(
				.visual_scene(
					id: "scene",
					.node(
						id: modelName,
						name: modelNameWithSpaces,
						.node(
							id: "\(modelName)-skeleton",
							type: "JOINT",
							mesh.bones
								.map {
									.node( // NOTE: if a bone name has a " in it, it'll break
										sid: $0.name,
										name: $0.name,
										type: "JOINT",
										.matrix(sid: "transform", $0.matrix)
									)
								}
						),
						.node(
							id: "\(modelName)-mesh",
							.instance_controller(
								controllerId: "\(modelName)-controller",
								.skeleton("\(modelName)-skeleton"),
								.bind_material(
									.technique_common(instanceMaterials)
								)
							)
						)
					)
				)
			),
			.scene(
				.instance_visual_scene(sceneId: "scene")
			)
		]
	}
}

fileprivate extension [[Matrix4x3<Double>]] {
	func transposed() -> [[Matrix4x3<Double>]] {
		guard let first else { return [] }
		let range = first.indices
		
		precondition(allSatisfy { $0.count == first.count })
		
		var result = [[Matrix4x3<Double>]]()
		result.reserveCapacity(first.count)
		
		for index in range {
			result.append(map { $0[index] })
		}
		
		return result
	}
}
