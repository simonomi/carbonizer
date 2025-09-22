import BinaryParser

func modelReparser(
	_ mar: inout MAR.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	guard try environment.modelTableNames().contains(path) else { return }
	
	let vertexFiles = try environment.get(\.vertexFiles)
	if let vertexIndices = vertexFiles[path] {
		for fileIndex in vertexIndices {
			guard mar.files.indices.contains(fileIndex) else {
				todo("invalid index")
			}
			
			guard let data = mar.files[fileIndex].content as? Datastream else {
				todo("invalid type")
			}
			
			let packed = try Datastream(data).read(VertexData.Packed.self) // copy to not modify the original
			mar.files[fileIndex].content = try packed.unpacked(configuration: configuration)
		}
	}
	
//	let textureFiles = try environment.get(\.textureFiles)
	
	
	
//	let animationFiles = try environment.get(\.animationFiles)
	
	
	
}
