struct USDSkeleton {
	var meshName: String
	var boneNames: [String]
	var restTransforms: [Matrix4x3<Double>]
	var animation: USDAnimation
	
	func string() -> String {
		let tupleTransforms = restTransforms.map {
			(
				($0.x.x, $0.x.y, $0.x.z, 0),
				($0.y.x, $0.y.y, $0.y.z, 0),
				($0.z.x, $0.z.y, $0.z.z, 0),
				($0.transform.x, $0.transform.y, $0.transform.z, 1)
			)
		}
		
		return """
			def Skeleton "skeleton" (
				prepend apiSchemas = ["SkelBindingAPI"]
			) {
				uniform token[] joints = \(boneNames)
				
				uniform matrix4d[] bindTransforms = \(tupleTransforms)
				
				uniform matrix4d[] restTransforms = \(tupleTransforms)
				
				rel skel:animationSource = </root/\(meshName)/skeleton/animation>
				
				\(animation.string().indented(by: 1))
			}
			"""
	}
}
