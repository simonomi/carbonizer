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

@Test(
//	.disabled("writing GPUCommands not implemented"),
	arguments: [
		"fieldchar 0000",
		"fieldchar 0003",
		"fieldchar 0005",
		"fieldchar 0007",
		"fieldchar 0025",
		"fieldchar 0067",
		"arcdin 0021",
		"arcdin 0045",
		"battle 0028",
		"fieldmap 0006",
	]
)
func meshRoundTrip(_ fileName: String) throws {
	let originalInputData = try Datastream(Data(contentsOf: filePath(for: fileName)))
	var inputData = originalInputData
	
	let packedMesh = try inputData.read(Mesh.Packed.self)
	
	let unpackedMesh = try packedMesh.unpacked(configuration: configuration)
	
	let repackedMesh = unpackedMesh.packed(configuration: configuration)
	
	let outputData = Datawriter()
	repackedMesh.write(to: outputData)
	
	try expectUnchanged(from: originalInputData.bytes, to: outputData.bytes, name: fileName)
}

@Test(arguments: ["fieldchar 0026", "fieldmap 0216", "battle 0250"])
func animationRoundTrip(_ fileName: String) throws {
	let originalInputData = try Datastream(Data(contentsOf: filePath(for: fileName)))
	var inputData = originalInputData
	
	let packedAnimation = try inputData.read(Animation.Packed.self)
	
	let unpackedAnimation = packedAnimation.unpacked(configuration: configuration)
	
	let repackedAnimation = unpackedAnimation.packed(configuration: configuration)
	
	let outputData = Datawriter()
	repackedAnimation.write(to: outputData)
	
	try expectUnchanged(from: originalInputData.bytes, to: outputData.bytes, name: fileName)
}

@Test(arguments: ["fieldchar 0027", "fieldmap 0103", "fieldchar 0667", "fieldchar 1493"])
func textureRoundTrip(_ fileName: String) throws {
	let originalInputData = try Datastream(Data(contentsOf: filePath(for: fileName)))
	var inputData = originalInputData
	
	let packedTexture = try inputData.read(Texture.Packed.self)
	
	let unpackedTexture = try packedTexture.unpacked(configuration: configuration)
	
	let repackedTexture = unpackedTexture.packed(configuration: configuration)
	
	let outputData = Datawriter()
	repackedTexture.write(to: outputData)
	
	try expectUnchanged(from: originalInputData.bytes, to: outputData.bytes, name: fileName)
}

fileprivate func filePath(for fileName: String) -> URL {
	.modelFilesDirectory
	.appending(component: fileName)
	.appendingPathExtension("bin")
}
