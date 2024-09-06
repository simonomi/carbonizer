import BinaryParser

struct Collada {
	var body: [XMLNode]
	
	func asString() -> String {
		let xmlHeader = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
		let collada: XMLNode = .collada(body)
		
		return xmlHeader + "\n" + collada.asString()
	}
}

fileprivate struct PolygonPoint {
	var vertexIndex: Int
	var textureInfo: TextureInfo?
	
	struct TextureInfo {
		var textureVertexIndex: Int
		var materialIndex: Int
	}
}

fileprivate struct CommandParsingState {
	var vertex: SIMD3<Double> = .zero // ?
	var vertexMode: GPUCommand.VertexMode?
	var bone: Int = -1
	
	var textureVertex: SIMD2<Double> = .zero // ?
	var textureScale: SIMD2<Double> = .one
	var material: String? // ?
	
	var vertices: [PolygonPoint] = []
	
	mutating func commitVertex(for result: inout CommandParsingResult, matrices: [Matrix4x3<Double>]) {
		if bone == -1 { fatalError("THE BONE IS NEGATIVE 1") }
		let vertex = vertex.transformed(by: matrices[bone])
		
		let textureInfo = material.map {
			PolygonPoint.TextureInfo(
				textureVertexIndex: result.index(of: textureVertex),
				materialIndex: result.index(of: $0)
			)
		}
		
		vertices.append(PolygonPoint(
			vertexIndex: result.index(of: vertex, bone: bone),
			textureInfo: textureInfo
		))
	}
	
	mutating func commitVertices(to result: inout CommandParsingResult) {
		let newPolygons: [ArraySlice<PolygonPoint>]
		
		// TODO: better nil check
		switch vertexMode! {
			case .triangle:
				guard vertices.count.isMultiple(of: 3) else {
					fatalError("TODO: throw here (triangle)")
				}
				newPolygons = vertices.chunked(exactSize: 3)
			case .quadrilateral:
				guard vertices.count.isMultiple(of: 4) else {
					fatalError("TODO: throw here (quadrilateral)")
				}
				newPolygons = vertices.chunked(exactSize: 4)
			case .triangleStrip:
				guard vertices.count >= 3 else {
					fatalError("TODO: throw here (triangleStrip)")
				}
				newPolygons = vertices
					.chunks(exactSize: 3, every: 1)
					.enumerated()
					.map { (index, vertices) in
						if index.isEven {
							[vertices[rel: 0], vertices[rel: 1], vertices[rel: 2]]
						} else {
							// reverse winding order
							[vertices[rel: 1], vertices[rel: 0], vertices[rel: 2]]
						}
					}
			case .quadrilateralStrip:
				guard vertices.count >= 4,
					  vertices.count.isMultiple(of: 2)
				else {
					fatalError("TODO: throw here (quadrilateralStrip)")
				}
				newPolygons = vertices
					.chunks(exactSize: 4, every: 2)
					.map { [$0[rel: 0], $0[rel: 1], $0[rel: 3], $0[rel: 2]] }
		}
		
		result.polygons[material, default: []].append(contentsOf: newPolygons.map(Array.init))
		vertices = []
	}
}

fileprivate struct CommandParsingResult {
	var vertices: [(SIMD3<Double>, bone: Int)] = []
	var textureVertices: [SIMD2<Double>] = []
	var materials: [String] = []
	var polygons: [String?: [[PolygonPoint]]] = [:]
	
	mutating func index(of vertex: SIMD3<Double>, bone: Int) -> Int {
		let vertex = (vertex, bone: bone)
		
		if let index = vertices.firstIndex(where: { $0 == vertex }) {
			return index
		} else {
			vertices.append(vertex)
			return vertices.count - 1
		}
	}
	
	mutating func index(of textureVertex: SIMD2<Double>) -> Int {
		if let index = textureVertices.firstIndex(where: { $0 == textureVertex }) {
			return index
		} else {
			textureVertices.append(textureVertex)
			return textureVertices.count - 1
		}
	}
	
	mutating func index(of material: String) -> Int {
		if let index = materials.firstIndex(where: { $0 == material }) {
			return index
		} else {
			materials.append(material)
			return materials.count - 1
		}
	}
}

extension Collada {
	// textureNames: a mapping from palette offset to texture file name. the offset should be normalized (bit shifted according to type)
	init(_ vertexData: VertexData, modelName: String, textureNames: [UInt32: String]) throws {
		// copy so theres no side effects
		let commandData = Datastream(vertexData.commands)
		let commands = try commandData.readCommands()
		
		let matrices = vertexData.boneTable.bones
			.map(\.matrix)
			.map(Matrix4x3.init)
		
		let initialState = (state: CommandParsingState(), result: CommandParsingResult())
		let (_, parsingResult) = commands
			.reduce(into: initialState) { partialResult, command in
				parseCommand(
					state: &partialResult.state,
					result: &partialResult.result,
					command: command,
					textureNames: textureNames,
					matrices: matrices
				)
			}
		
		let boneCount = vertexData.boneTable.bones.count
		
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
						.image(
							id: "\(materialName)-image",
							.init_from("\(materialName).png")
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
								)
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
								vertexData.boneTable.bones.map(\.name)
							),
							.technique_common(
								.accessor(
									sourceId: "\(modelName)-joints-array",
									count: boneCount,
									.param(name: "JOINT", type: "Name")
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
								matrices
									.map { $0.inverse() ?? $0.badInverse() }
									.flatMap { $0.as4x4Array() }
							),
							.technique_common(
								.accessor(
									sourceId: "\(modelName)-inverse-bind-matrix-array",
									count: boneCount,
									stride: 16,
									.param(name: "TRANSFORM", type: "float4x4") // TODO: 4x3? 3x4?
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
			.library_visual_scenes(
				.visual_scene(
					id: "scene",
					.node(
						id: "skeleton",
						type: "JOINT",
						vertexData.boneTable.bones
							.map(\.name) // NOTE: if a bone name has a " in it, it'll break
							.map { .node(sid: $0, name: $0, type: "JOINT") }
					),
					.node(
						id: modelName,
						.instance_controller(
							controllerId: "\(modelName)-controller",
							.skeleton("skeleton"),
							.bind_material(
								.technique_common(instanceMaterials)
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

fileprivate func parseCommand(
	state: inout CommandParsingState,
	result: inout CommandParsingResult,
	command: GPUCommand,
	textureNames: [UInt32: String],
	matrices: [Matrix4x3<Double>]
) {
	switch command {
		case .noop: ()
		case .matrixMode(_): () // ignore for now
		case .matrixPop(_): () // ignore for now
		case .matrixRestore(let index):
			state.bone = Int(index) - 5
		case .matrixIdentity:
			state.bone = -1 // TODO: this should be handled wayyyy better
							// wait or is this accidentally right??
		case .matrixLoad4x3(_): () // ignore for now
		case .matrixScale(_, _, _): () // ignore for now
		case .color(_): () // ignore for now
		case .normal(_): () // ignore for now
		case .textureCoordinate(let textureVertex):
			state.textureVertex = (textureVertex * state.textureScale).flippedVertically()
		case .vertex16(let vertex):
			state.vertex = vertex
			state.commitVertex(for: &result, matrices: matrices)
		case .vertexXY(let x, let y):
			state.vertex.x = x
			state.vertex.y = y
			state.commitVertex(for: &result, matrices: matrices)
		case .vertexXZ(let x, let z):
			state.vertex.x = x
			state.vertex.z = z
			state.commitVertex(for: &result, matrices: matrices)
		case .vertexYZ(let y, let z):
			state.vertex.y = y
			state.vertex.z = z
			state.commitVertex(for: &result, matrices: matrices)
		case .polygonAttributes(_): () // ignore for now
		case .textureImageParameter(let raw):
			state.textureScale = SIMD2(
				textureSize(for: raw >> 20 & 0b111),
				textureSize(for: raw >> 23 & 0b111)
			)
		case .texturePaletteBase(let index):
			// TODO: should have some fallback for this case?
			precondition(state.vertices.isEmpty, "Uh oh, a model has multiple textures for the same polygon, but collada doesn't support that")
			
			state.material = textureNames[index]
		case .vertexBegin(let vertexMode):
			state.vertexMode = vertexMode
		case .vertexEnd:
			state.commitVertices(to: &result)
		case .unknown50(_, _): () // ignore for now
		case .unknown51(_, _): () // ignore for now
		case .commandsStart(_): ()
		case .unknown53(_, _, _): () // ignore for now
		case .commandsEnd: ()
	}
}

extension SIMD2 where Scalar: FloatingPoint {
	fileprivate func flippedVertically() -> Self {
		Self(x: x, y: 1 - y)
	}
}