struct USDAnimation {
	var boneNames: [String]
	var transforms: [[Matrix4x3<Double>]]
	
	func string() -> String {
		let scales = transforms
			.enumerated()
			.map { index, boneTransforms in
				let boneTuples = boneTransforms
					.map {
						return (
							$0.x.vectorLength(),
							$0.y.vectorLength(),
							$0.z.vectorLength()
						)
					}
				
				return "\(index): \(boneTuples)"
			}
			.joined(separator: ",\n\t\t")
		
		let rotations = transforms
			.enumerated()
			.map { index, boneTransforms in
				let boneTuples = boneTransforms
					.map {
						// following https://en.wikipedia.org/wiki/Rotation_matrix#Quaternion
						let t = $0.x.x + $0.y.y + $0.z.z
						let r = (1 + t).squareRoot()
						let s = 1 / (2 * r)
						
						return (
							(1 / 2) * r,
							($0.y.z - $0.z.y) * s,
							($0.z.x - $0.x.z) * s,
							($0.x.y - $0.y.x) * s
						)
					}
				
				return "\(index): \(boneTuples)"
			}
			.joined(separator: ",\n\t\t")
		
		let translationSamples = transforms
			.enumerated()
			.map { index, boneTransforms in
				let boneTuples = boneTransforms
					.map(\.translation)
					.map { ($0.x, $0.y, $0.z) }
				
				return "\(index): \(boneTuples)"
			}
			.joined(separator: ",\n\t\t")
		
		// TODO: transforms arent valid -_-
		// must use rotation/scale/translation
		// - how to get those from transforms??
		return """
			def SkelAnimation "animation" {
				uniform token[] joints = \(boneNames)
				
				half3[] scales.timeSamples = {
					\(scales)
				}
				
				quatf[] rotations.timeSamples = {
					\(rotations)
				}
				
				float3[] translations.timeSamples = {
					\(translationSamples)
				}
			}
			"""
	}
}
