struct USDAnimation {
	var boneNames: [String]
	
	func string() -> String {
		"""
		def SkelAnimation "animation" {
			uniform token[] joints = \(boneNames)
			
			matrix4d[] transforms.timeSamples = {} // TODO: this
		}
		"""
	}
}
