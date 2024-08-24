import BinaryParser

struct Collada {
	var body: [XMLNode]
	
	func asString() -> String {
		let hasAsset = body.contains { $0.kind == "asset" }
		let bodyWithAsset = if hasAsset {
				body
			} else {
				[.asset()] + body
			}
		
		let xmlHeader = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
		let collada: XMLNode = .collada(bodyWithAsset)
		
		return xmlHeader + "\n" + collada.asString()
	}
}

extension Collada {
	init(_ vertexData: VertexData, modelName: String) throws {
		// NOTE: if a bone name has a " in it, it'll break
		let boneName = vertexData.boneTable.bones.first?.name ?? "no bones :("
		
		// copy so theres no side effects
		let commandData = Datastream(vertexData.commands)
		let commands = try commandData.readCommands()
		
		var vertices: [(SIMD3<Double>, bone: Int)] = []
		var polygons: [[Int]] = []
		
		var currentVertexMode: GPUCommand.VertexMode?
		var currentVertex: SIMD3<Double> = .zero
		var currentVertices: [Int] = []
		
		func commitVertex() {
			let vertex = (currentVertex, bone: 1)
			
			let vertexIndex: Int
			if let index = vertices.firstIndex(where: { $0 == vertex }) {
				vertexIndex = index
			} else {
				vertexIndex = vertices.count
				vertices.append(vertex)
			}
			
			currentVertices.append(vertexIndex)
		}
		
		func commitVertices() {
			let newPolygons: [ArraySlice<Int>]
			switch currentVertexMode! {
				case .triangle:
					guard currentVertices.count.isMultiple(of: 3) else {
						fatalError("TODO: throw here (triangle)")
					}
					newPolygons = currentVertices.chunked(exactSize: 3)
				case .quadrilateral:
					guard currentVertices.count.isMultiple(of: 4) else {
						fatalError("TODO: throw here (quadrilateral)")
					}
					newPolygons = currentVertices.chunked(exactSize: 4)
				case .triangleStrip:
					guard currentVertices.count >= 3 else {
						fatalError("TODO: throw here (triangleStrip)")
					}
					newPolygons = currentVertices
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
					guard currentVertices.count >= 4,
						  currentVertices.count.isMultiple(of: 2)
					else {
						fatalError("TODO: throw here (quadrilateralStrip)")
					}
					newPolygons = currentVertices
						.chunks(exactSize: 4, every: 2)
						.map {
							[$0[rel: 0], $0[rel: 1], $0[rel: 3], $0[rel: 2]]
						}
			}
			
			polygons.append(contentsOf: newPolygons.map(Array.init))
		}
		
		for command in commands {
			switch command {
				case .noop: ()
				case .matrixMode(_): () // ignore for now
				case .matrixPop(_): () // ignore for now
				case .matrixRestore(let index):
//					print("restore", index)
					() // ignore for now
				case .matrixIdentity:
//					print("identity")
					() // ignore for now
				case .matrixScale(_, _, _): () // ignore for now
				case .color(_): () // ignore for now
				case .textureCoordinate(_, _): () // ignore for now
				case .vertex16(let x, let y, let z):
					currentVertex = SIMD3(x, y, z)
					commitVertex()
				case .vertexXY(let x, let y):
					currentVertex.x = x
					currentVertex.y = y
					commitVertex()
				case .vertexXZ(let x, let z):
					currentVertex.x = x
					currentVertex.z = z
					commitVertex()
				case .vertexYZ(let y, let z):
					currentVertex.y = y
					currentVertex.z = z
					commitVertex()
				case .polygonAttributes(_): () // ignore for now
				case .textureImageParameter(_): () // ignore for now
				case .texturePaletteBase(_): () // ignore for now
				case .vertexBegin(let vertexMode):
					currentVertices = []
					currentVertexMode = vertexMode
				case .vertexEnd:
					commitVertices()
				case .unknown50(_, _): () // ignore for now
				case .unknown51(_, _): () // ignore for now
				case .commandsStart(_): ()
				case .unknown53(_, _, _): () // ignore for now
				case .commandsEnd: ()
			}
		}
		
		body = [
			.library_geometries(
				.geometry(
					id: boneName,
					.mesh(
						.source(
							id: "\(boneName)-vertices-source",
							.float_array(
								id: "\(boneName)-vertices-array",
								vertices.map(\.0).flatMap {[ $0.x, $0.y, $0.z ]}
							),
							.technique_common(
								.accessor(
									sourceId: "\(boneName)-vertices-array",
									count: vertices.count,
									stride: 3,
									.param(name: "X", type: "float"),
									.param(name: "Y", type: "float"),
									.param(name: "Z", type: "float")
								)
							)
						),
						.vertices(
							id: "\(boneName)-vertices",
							.input(semantic: "POSITION", sourceId: "\(boneName)-vertices-source")
						),
						.polylist(
							count: "2",
							.input(semantic: "VERTEX", sourceId: "\(boneName)-vertices", offset: 0),
							.vcount(polygons.map(\.count)),
							.p(Array(polygons.joined()))
						)
					)
				)
			),
			.library_visual_scenes(
				.visual_scene(
					id: "scene",
					.node(
						id: modelName,
						.instance_geometry(geometryId: boneName)
					)
				)
			),
			.scene(
				.instance_visual_scene(sceneId: "scene")
			)
		]
	}
}
