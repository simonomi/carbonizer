struct USDMaterial {
	var name: String
	var meshName: String
	var subsetName: String
	var texturePath: String
	
	func string() -> String {
		"""
		def Material "\(subsetName)" {
			token outputs:surface.connect = </\(meshName)/\(meshName)_mesh/\(subsetName)/\(subsetName)/surface.outputs:surface>
			
			def Shader "surface" {
				uniform token info:id = "UsdPreviewSurface"
				color3f inputs:diffuseColor.connect = </\(meshName)/\(meshName)_mesh/\(subsetName)/\(subsetName)/texture.outputs:rgb>
				float inputs:opacity.connect = </\(meshName)/\(meshName)_mesh/\(subsetName)/\(subsetName)/texture.outputs:a>
				token outputs:surface
			}
			
			def Shader "texture" {
				uniform token info:id = "UsdUVTexture"
				asset inputs:file = @\(texturePath)/\(name).bmp@
				float2 inputs:st.connect = </\(meshName)/\(meshName)_mesh/\(subsetName)/\(subsetName)/uvMap.outputs:result>
				float3 outputs:rgb
				float outputs:a
			}
			
			def Shader "uvMap" {
				uniform token info:id = "UsdPrimvarReader_float2"
				string inputs:varname = "st"
				float2 outputs:result
			}
		}
		"""
	}
}
