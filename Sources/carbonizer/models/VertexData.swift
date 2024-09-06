import BinaryParser

@BinaryConvertible
struct Matrix4x3_2012 {
	var x: Vector3_2012
	var y: Vector3_2012
	var z: Vector3_2012
	var transform: Vector3_2012
}

@BinaryConvertible
struct Vector3_2012 {
	var x: Fixed2012
	var y: Fixed2012
	var z: Fixed2012
}

@BinaryConvertible
struct Fixed2012 {
	var raw: Int32
}

@BinaryConvertible
struct VertexData {
	var unknown1: UInt32 = 0x20000
	
	var commandsOffset: UInt32 = 0x28
	var commandsLength: UInt32
	
	var boneTableLength: UInt32
	
	var modelNamesLength: UInt32
	
	var unknown2: UInt32 // (1...27).filter(\.isOdd) except 21
	var unknown3: UInt32 // no clue what this number means but when its 0 its all funky
						 // 0, 0x100, 0x101, 0x102
	var unknown4: UInt32 // 1, 2, 3, 4, 5, 6, 9
	var unknown5: UInt32 // lots of values 1...300
	
	var unknown6: UInt32 // usually half of 0x8??
	
	@Offset(givenBy: \Self.commandsOffset)
	@Length(givenBy: \Self.commandsLength)
	var commands: Datastream
	
	@Offset(givenBy: \Self.commandsOffset, .plus(\Self.commandsLength))
	var boneTable: BoneTable
	
	@Offset(givenBy: \Self.commandsOffset, .plus(\Self.commandsLength), .plus(\Self.boneTableLength))
	var modelNames: ModelNames
	
	@BinaryConvertible
	struct BoneTable {
		var boneCount: UInt32
		
		@Count(givenBy: \Self.boneCount)
		var bones: [Bone]
		
		@BinaryConvertible
		struct Bone {
			@Length(16)
			var name: String
			var matrix: Matrix4x3_2012
		}
	}
	
	@BinaryConvertible
	struct ModelNames {
		var nameCount: UInt32
		
		@Count(givenBy: \Self.nameCount)
		var names: [FixedLengthString]
		
		@BinaryConvertible
		struct FixedLengthString {
			@Length(16)
			var string: String
		}
	}
}

extension SIMD3<Double> {
	init(_ vector3_2012: Vector3_2012) {
		self.init(
			Double(vector3_2012.x),
			Double(vector3_2012.y),
			Double(vector3_2012.z)
		)
	}
}

extension Double {
	init(_ fixed2012: Fixed2012) {
		self = Double(fixed2012.raw) / Double(1 << 12)
	}
}

extension SIMD3 where Scalar: FloatingPoint {
	consuming func transformed(by matrix: Matrix4x3<Scalar>) -> Self {
		x * matrix.x + y * matrix.y + z * matrix.z + matrix.transform
	}
}

extension Collection where Index == Int {
	subscript(rel relativeIndex: Index) -> Element {
		self[startIndex + relativeIndex]
	}
}

extension VertexData {
	/// creates an OBJ
	/// - Parameters:
	///   - matrices: the stack of matrices (usually offset by 5)
	///   - textureNames: a mapping from palette offset to texture file name. the offset should be normalized (bit shifted according to type)
	/// - Returns: an OBJ
	func obj(
		matrices: [Matrix4x3_2012]? = nil,
		textureNames: [UInt32: String]
	) throws -> OBJ<Double> {
		let matrices = (matrices ?? self.boneTable.bones.map(\.matrix))
			.map(Matrix4x3.init)
		
		// copy so theres no side effects
		let commandData = Datastream(self.commands)
		
		let commands = try commandData.readCommands()
		
		var textureScale: SIMD2<Double> = SIMD2(1, 1)
		
		var currentMatrix: Matrix4x3<Double>?
		var currentVertexMode: GPUCommand.VertexMode?
		var currentVertex: SIMD3<Double> = .zero
		var currentTextureVertex: SIMD2<Double> = .zero
		var currentVertices: [(Int, texture: Int)] = []
		var result = OBJ<Double>()
		
		func commitVertex() {
			guard let currentMatrix else {
				fatalError("currentMatrix was nil")
			}
			
			let vertex = currentVertex.transformed(by: currentMatrix)
			
			let vertexIndex: Int // plus 1 because 1-indexed
			if let index = result.vertices.firstIndex(of: vertex) {
				vertexIndex = index + 1
			} else {
				result.vertices.append(vertex)
				vertexIndex = result.vertices.count
			}
			
			// flip vertically
			let textureVertex = SIMD2(
				currentTextureVertex.x,
				1 - currentTextureVertex.y
			)
			
			let textureVertexIndex: Int // plus 1 because 1-indexed
			if let index = result.textureVertices.firstIndex(of: textureVertex) {
				textureVertexIndex = index + 1
			} else {
				result.textureVertices.append(textureVertex)
				textureVertexIndex = result.textureVertices.count
			}
			
			currentVertices.append((vertexIndex, textureVertexIndex))
		}
		
		func commitVertices() {
			let newFaces: [(SIMD3<Int>, SIMD3<Int>)]
			switch currentVertexMode! {
				case .triangle:
					guard currentVertices.count.isMultiple(of: 3) else {
						fatalError("TODO: throw here")
					}
					newFaces = currentVertices
						.chunked(exactSize: 3)
						.map {(
							SIMD3($0[rel: 0].0, $0[rel: 1].0, $0[rel: 2].0),
							SIMD3($0[rel: 0].1, $0[rel: 1].1, $0[rel: 2].1)
						)}
				case .quadrilateral:
					guard currentVertices.count.isMultiple(of: 4) else {
						fatalError("TODO: throw here")
					}
					newFaces = currentVertices
						.chunked(exactSize: 4)
						.flatMap {[
							(SIMD3($0[rel: 0].0, $0[rel: 1].0, $0[rel: 3].0),
							 SIMD3($0[rel: 0].1, $0[rel: 1].1, $0[rel: 3].1)),
							(SIMD3($0[rel: 1].0, $0[rel: 2].0, $0[rel: 3].0),
							 SIMD3($0[rel: 1].1, $0[rel: 2].1, $0[rel: 3].1))
						]}
				case .triangleStrip:
					guard currentVertices.count >= 3 else {
						fatalError("TODO: throw here")
					}
					newFaces = currentVertices
						.chunks(exactSize: 3, every: 1)
						.enumerated()
						.map { (index, vertices) in
							if index.isEven {
								(SIMD3(vertices[rel: 0].0, vertices[rel: 1].0, vertices[rel: 2].0),
								 SIMD3(vertices[rel: 0].1, vertices[rel: 1].1, vertices[rel: 2].1))
							} else {
								// reverse winding order
								(SIMD3(vertices[rel: 1].0, vertices[rel: 0].0, vertices[rel: 2].0),
								 SIMD3(vertices[rel: 1].1, vertices[rel: 0].1, vertices[rel: 2].1))
							}
						}
				case .quadrilateralStrip:
					guard currentVertices.count >= 4,
						  currentVertices.count.isMultiple(of: 2)
					else {
						fatalError("TODO: throw here")
					}
					newFaces = currentVertices
						.chunks(exactSize: 4, every: 2)
						.flatMap {[
							(SIMD3($0[rel: 0].0, $0[rel: 1].0, $0[rel: 2].0),
							 SIMD3($0[rel: 0].1, $0[rel: 1].1, $0[rel: 2].1)),
							(SIMD3($0[rel: 1].0, $0[rel: 3].0, $0[rel: 2].0),
							 SIMD3($0[rel: 1].1, $0[rel: 3].1, $0[rel: 2].1))
						]}
			}
			
			let newPolygons = newFaces.map {
				OBJ<Double>.Polygon.face($0.0, texture: $0.1)
			}
			
			result.polygons.append(contentsOf: newPolygons)
		}
		
		for command in commands {
			switch command {
				case .noop: ()
				case .matrixMode(_): () // ignore for now
				case .matrixPop(_): () // ignore for now
				case .matrixRestore(let index):
					currentMatrix = matrices[Int(index) - 5]
				case .matrixIdentity:
					currentMatrix = .identity
				case .matrixLoad4x3(_): () // ignore for now
				case .matrixScale(_, _, _): () // ignore for now
				case .color(_): () // ignore for now
				case .normal(_): () // ignore for now
				case .textureCoordinate(let textureVertex):
					currentTextureVertex = textureVertex * textureScale
				case .vertex16(let vertex):
					currentVertex = vertex
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
				case .textureImageParameter(let raw):
					textureScale = SIMD2(
						textureSize(for: raw >> 20 & 0b111),
						textureSize(for: raw >> 23 & 0b111)
					)
				case .texturePaletteBase(let value):
					// if a texture isn't found, just use a blank one
					let textureName = textureNames[value] ?? "none"
					result.polygons.append(.useTexture(textureName))
				case .vertexBegin(let vertexMode):
					currentVertices = []
					currentVertexMode = vertexMode
				case .vertexEnd:
					commitVertices()
				case .unknown50: () // ignore for now
				case .unknown51: () // ignore for now
				case .commandsStart: ()
				case .unknown53: () // ignore for now
				case .commandsEnd: ()
			}
		}
		
		return result
	}
}

func textureSize(for scale: UInt32) -> Double {
	// inverse bc obj and collada texture coords are normalized
	1 / Double(8 << scale)
}
