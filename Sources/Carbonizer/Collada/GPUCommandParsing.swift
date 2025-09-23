struct PolygonPoint {
	var vertexIndex: Int
	var textureInfo: TextureInfo?
	
	struct TextureInfo {
		var textureVertexIndex: Int
		var materialIndex: Int
	}
}

enum ModelParsingError: Error, CustomStringConvertible {
	case negativeOneBone
	
	var description: String {
		switch self {
			case .negativeOneBone:
				"THE BONE IS NEGATIVE 1"
		}
	}
}

fileprivate struct CommandParsingState {
	var vertex: SIMD3<Double> = .zero // ?
	var vertexMode: GPUCommands.Command.VertexMode?
	var bone: Int = -1
	
	var worldRootBoneCount: Int = 0
	
	var textureVertex: SIMD2<Double> = .zero // ?
	var textureScale: SIMD2<Double> = .one
	var material: String? // ?
	
	var vertices: [PolygonPoint] = []
	
	mutating func commitVertex(for result: inout CommandParsingResult, matrices: [Matrix4x3<Double>]) throws {
		if bone == -1 {
			throw ModelParsingError.negativeOneBone
		}
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
					todo("throw here (triangle)")
				}
				newPolygons = vertices.chunked(exactSize: 3)
			case .quadrilateral:
				guard vertices.count.isMultiple(of: 4) else {
					todo("throw here (quadrilateral)")
				}
				newPolygons = vertices.chunked(exactSize: 4)
			case .triangleStrip:
				guard vertices.count >= 3 else {
					todo("throw here (triangleStrip)")
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
					todo("throw here (quadrilateralStrip)")
				}
				newPolygons = vertices
					.chunks(exactSize: 4, every: 2)
					.map { [$0[rel: 0], $0[rel: 1], $0[rel: 3], $0[rel: 2]] }
		}
		
		result.polygons[material, default: []].append(contentsOf: newPolygons.map(Array.init))
		vertices = []
	}
}

struct CommandParsingResult {
	var vertices: [(SIMD3<Double>, bone: Int)] = []
	var textureVertices: [SIMD2<Double>] = []
	var materials: [String] = []
	var polygons: [String?: [[PolygonPoint]]] = [:]
	
	fileprivate mutating func index(of vertex: SIMD3<Double>, bone: Int) -> Int {
		let vertex = (vertex, bone: bone)
		
		if let index = vertices.firstIndex(where: { $0 == vertex }) {
			return index
		} else {
			vertices.append(vertex)
			return vertices.count - 1
		}
	}
	
	fileprivate mutating func index(of textureVertex: SIMD2<Double>) -> Int {
		if let index = textureVertices.firstIndex(where: { $0 == textureVertex }) {
			return index
		} else {
			textureVertices.append(textureVertex)
			return textureVertices.count - 1
		}
	}
	
	fileprivate mutating func index(of material: String) -> Int {
		if let index = materials.firstIndex(where: { $0 == material }) {
			return index
		} else {
			materials.append(material)
			return materials.count - 1
		}
	}
}

func parseCommands(
	_ commands: [GPUCommands.Command],
	textureNames: [UInt32: String],
	matrices: [Matrix4x3<Double>]
) throws -> CommandParsingResult {
	let initialState = (state: CommandParsingState(), result: CommandParsingResult())
	return try commands
		.reduce(into: initialState) { partialResult, command in
			try parseCommand(
				state: &partialResult.state,
				result: &partialResult.result,
				command: command,
				textureNames: textureNames,
				matrices: matrices
			)
		}.result
}

fileprivate func parseCommand(
	state: inout CommandParsingState,
	result: inout CommandParsingResult,
	command: GPUCommands.Command,
	textureNames: [UInt32: String],
	matrices: [Matrix4x3<Double>]
) throws {
	switch command {
		case .noop: ()
		case .matrixMode(_): () // ignore for now
		case .matrixPop(_): () // ignore for now
		case .matrixRestore(let index):
			state.bone = Int(index) - 5 + state.worldRootBoneCount
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
			try state.commitVertex(for: &result, matrices: matrices)
		case .vertexXY(let x, let y):
			state.vertex.x = x
			state.vertex.y = y
			try state.commitVertex(for: &result, matrices: matrices)
		case .vertexXZ(let x, let z):
			state.vertex.x = x
			state.vertex.z = z
			try state.commitVertex(for: &result, matrices: matrices)
		case .vertexYZ(let y, let z):
			state.vertex.y = y
			state.vertex.z = z
			try state.commitVertex(for: &result, matrices: matrices)
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
		case .unknown51(_, let bytes):
			state.worldRootBoneCount = Int(bytes[12]) // idk, this byte just seems to be the number of 'world_root' bones
													  // theres more to do here probably
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
