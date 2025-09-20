enum ProcessorError: Error, CustomStringConvertible {
	case missingEnvironment(String)
	
	var description: String {
		switch self {
			case .missingEnvironment(let string):
				"missing environment data \(.cyan)'\(string)'\(.normal)"
		}
	}
}
