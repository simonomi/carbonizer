protocol Mesh {
	associatedtype Bone: MeshBone
	
	var bones: [Bone]? { get }
	
	func gpuCommands() throws -> [GPUCommands.Command]
	
	func worldRootBoneCount() throws -> Int
}

protocol MeshBone {
	var name: String { get }
	var matrix: Matrix4x3<Double> { get }
}
