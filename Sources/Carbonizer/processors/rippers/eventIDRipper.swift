func eventIDRipperF(
	_ mar: inout MAR.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	guard mar.files.count == 1,
		  let dep = mar.files.first?.content as? DEP.Unpacked
	else {
		return
	}
	
	if environment.eventIDs == nil {
		environment.eventIDs = [:]
	}
	
	guard environment.eventIDs![mar.name] == nil else {
		throw DuplicateDEPFiles(name: mar.name)
	}
	
	environment.eventIDs![mar.name] = dep.events.map(\.id)
}

struct DuplicateDEPFiles: Error, CustomStringConvertible {
	var name: String
	
	var description: String {
		"there are two DEP files both named \(.cyan)'\(name)'\(.normal)"
	}
}
