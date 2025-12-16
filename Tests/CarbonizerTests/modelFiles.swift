import Foundation
import Testing

import BinaryParser
@testable import Carbonizer

//("fieldchar 0025", .packed), // mesh
//("fieldchar 0026", .packed), // model animation
//("fieldchar 0027", .packed), // texture

fileprivate let configuration = try! Configuration(
	overwriteOutput: true,
	game: .ff1,
	externalMetadata: false,
	fileTypes: [],
	onlyUnpack: [],
	skipUnpacking: [],
	compression: false,
	processors: [],
	logHandler: nil
)

@Test(.disabled(), arguments: ["fieldchar 0025"])
func meshRoundTrip(_ fileName: String) throws {
	let inputData = try Datastream(Data(contentsOf: filePath(for: fileName)))
	
	let packedMesh = try inputData.read(Mesh.Packed.self)
	
	let unpackedMesh = try packedMesh.unpacked(configuration: configuration)
	
	let repackedMesh = unpackedMesh.packed(configuration: configuration)
	
	let outputData = Datawriter()
	repackedMesh.write(to: outputData)
	
	try expectUnchanged(from: inputData.bytes, to: outputData.bytes, name: fileName)
}

@Test(arguments: ["fieldchar 0026", "fieldmap 0216", "battle 0250"])
func animationRoundTrip(_ fileName: String) throws {
	let inputData = try Datastream(Data(contentsOf: filePath(for: fileName)))
	
	let packedAnimation = try inputData.read(Animation.Packed.self)
	
	let unpackedAnimation = packedAnimation.unpacked(configuration: configuration)
	
	let repackedAnimation = unpackedAnimation.packed(configuration: configuration)
	
	let outputData = Datawriter()
	repackedAnimation.write(to: outputData)
	
	try expectUnchanged(from: inputData.bytes, to: outputData.bytes, name: fileName)
}

@Test(arguments: ["fieldchar 0027"])
func textureRoundTrip(_ fileName: String) throws {
	let inputData = try Datastream(Data(contentsOf: filePath(for: fileName)))
	
	let packedTexture = try inputData.read(Texture.Packed.self)
	
	let unpackedTexture = try packedTexture.unpacked(configuration: configuration)
	
	let repackedTexture = unpackedTexture.packed(configuration: configuration)
	
	let outputData = Datawriter()
	repackedTexture.write(to: outputData)
	
	try expectUnchanged(from: inputData.bytes, to: outputData.bytes, name: fileName)
}

fileprivate func filePath(for fileName: String) -> URL {
	.modelFilesDirectory
	.appending(component: fileName)
	.appendingPathExtension("bin")
}
