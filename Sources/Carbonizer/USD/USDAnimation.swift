struct USDAnimation {
	var boneNames: [String]
	var transforms: [[Matrix4x3<Double>]]
	
	func string() -> String {
		let transformSamples = transforms
			.enumerated()
			.map { index, boneTransforms in
				let boneTuples = boneTransforms.map {
					(
						($0.x.x, $0.x.y, $0.x.z, 0),
						($0.y.x, $0.y.y, $0.y.z, 0),
						($0.z.x, $0.z.y, $0.z.z, 0),
						($0.transform.x, $0.transform.y, $0.transform.z, 1)
					)
				}
				
				return "\(index): [\(boneTuples)]"
			}
			.joined(separator: ",\n\t\t")
		
		// TODO: transforms arent valid -_-
		// must use rotation/scale/translation
		// - how to get those from transforms??
		return """
			def SkelAnimation "animation" {
				uniform token[] joints = \(boneNames)
				
				matrix4d[] transforms.timeSamples = {
					\(transformSamples)
				}
			}
			"""
	}
}
