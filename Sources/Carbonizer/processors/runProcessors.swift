func runProcessors(
	on file: inout any FileSystemObject,
	when: PackOrUnpack,
	configuration: Configuration
) throws {
	let processorsToRun = configuration.processors
		.filter { $0.shouldRunWhen == when }
	
	for processor in processorsToRun {
		for fileType in processor.requiredFileTypes {
			guard configuration.fileTypes.contains(fileType) else {
				throw FileTypeNotEnabled(fileType: fileType, processor: processor)
			}
		}
	}
	
	let pipeline = processorsToRun
		.map(\.stages)
		.pipelined()
	
	var environment = Processor.Environment()
	
	for step in pipeline {
		// TODO: flip this loop, so only one run call that takes a list of stages
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
