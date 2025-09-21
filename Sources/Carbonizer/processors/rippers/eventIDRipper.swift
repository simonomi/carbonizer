func eventIDRipperF(
	_ mar: inout MAR.Unpacked,
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	guard mar.files.count == 1,
		  let dep = mar.files.first?.content as? DEP.Unpacked
	else {
		return
	}
	
	if environment.blockIDs == nil {
		environment.blockIDs = [:]
	}
	
	guard environment.blockIDs![mar.name] == nil else {
		throw DuplicateDEPFiles(name: mar.name)
	}
	
	environment.blockIDs![mar.name] = dep.blocks.map(\.id)
}

struct DuplicateDEPFiles: Error, CustomStringConvertible {
	var name: String
	
	var description: String {
		"there are two DEP files both named \(.cyan)'\(name)'\(.normal)"
	}
}
