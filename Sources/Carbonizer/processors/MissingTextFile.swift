struct MissingTextFile: Error, CustomStringConvertible {
	var name: String
	
	var description: String {
		"couldn't find unpacked text file \(.red)\(name)\(.normal)"
	}
}
