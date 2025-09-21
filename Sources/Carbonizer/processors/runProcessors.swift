func runProcessors(
	on file: inout any FileSystemObject,
	when: PackOrUnpack,
	configuration: Configuration
) throws {
	let pipeline = configuration.processors
		.filter { $0.shouldRunWhen == when }
		.map(\.stages)
		.pipelined()
	
	var environment = Processor.Environment()
	
	for step in pipeline {
		for stage in step {
			try stage.run(on: &file, in: &environment, configuration: configuration)
		}
	}
}

extension [[Processor.Stage]] {
	// group all the stage-1s together, and the stage-2s, and so on
	func pipelined() -> [Set<Processor.Stage>] {
		guard isNotEmpty else { return [] }
		
		let maxCount = self.map(\.count).max()!
		var result = [Set<Processor.Stage>](repeating: [], count: maxCount)
		
		for processor in self {
			for (index, stage) in processor.enumerated() {
				result[index].insert(stage)
			}
		}
		
		return result
	}
}
