func depEventLabellerF(
	_ dep: inout DEP.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	for eventIndex in dep.events.indices {
		dep.events[eventIndex].requirements = dep.events[eventIndex].requirements
			.reduce(into: []) { partialResult, requirement in
				for event in requirement.events() {
					if let label = eventLabels[event] {
						partialResult.append(.comment(label))
					}
				}
				
				partialResult.append(requirement)
			}
	}
}
