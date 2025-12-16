struct USDMaterial {
	var name: String
	var meshName: String
	var texturePath: String
	
	func string() -> String {
		"""
		def Material "material" {
			token outputs:surface.connect = </root/\(meshName)/material/surface.outputs:surface>
			
			def Shader "surface" {
				uniform token info:id = "UsdPreviewSurface"
				color3f inputs:diffuseColor.connect = </root/\(meshName)/material/texture.outputs:rgb>
				token outputs:surface
			}
			
			def Shader "texture" {
				uniform token info:id = "UsdUVTexture"
				asset inputs:file = @\(texturePath)/\(name).bmp@
				float2 inputs:st.connect = </root/\(meshName)/material/uvMap.outputs:result>
				float3 outputs:rgb
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
