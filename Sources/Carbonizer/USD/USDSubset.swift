struct USDSubset {
	var name: String
	var meshName: String
	var faceIndices: [Int]
	
	var material: USDMaterial?
	
	func string() -> String {
		let materialBinding = if material != nil {
				"rel material:binding = </\(meshName)/\(meshName)_mesh/\(name)/\(name)>"
			} else {
				""
			}
		
		let materialDefinition = material.map {
			$0.string().indented(by: 1)
		} ?? ""
		
		return """
			def GeomSubset "\(name)" (
				prepend apiSchemas = ["MaterialBindingAPI"]
			) {
				uniform token elementType = "face"
				uniform token familyName = "materialBind"
				uniform int[] indices = \(faceIndices)
				
				\(materialBinding)
				
				\(materialDefinition)
			}
			"""
	}
}
