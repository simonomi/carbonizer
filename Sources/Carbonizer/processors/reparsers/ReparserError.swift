enum ReparserError: Error, CustomStringConvertible {
	case invalidIndex(Int, for: String)
	case invalidType(Int, for: String)
	
	var description: String {
		switch self {
			case .invalidIndex(let index, for: let fileType):
				"could not find \(fileType) at index \(.red)\(index)\(.normal)"
			case .invalidType(let index, for: let fileType):
				"tried to parse \(fileType) at \(index) when already parsed as something else"
		}
	}
}
