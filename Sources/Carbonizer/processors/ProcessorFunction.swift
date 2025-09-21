typealias ProcessorFunction<T> = (
	inout T,
	_ environment: inout Processor.Environment,
	_ configuration: Configuration
) throws -> Void

extension NDS.Unpacked {
	mutating func runProcessor<T>(
		_ processor: ProcessorFunction<T>,
		on glob: Glob,
		in environment: inout Processor.Environment,
		at path: [String],
		configuration: Configuration
	) throws {
		for index in contents.indices {
			try contents[index].runProcessor(
				processor,
				on: glob,
				in: &environment,
				at: path,
				configuration: configuration
			)
		}
	}
}

extension NDS.Packed {
	mutating func runProcessor<T>(
		_ processor: ProcessorFunction<T>,
		on glob: Glob,
		in environment: inout Processor.Environment,
		at path: [String],
		configuration: Configuration
	) throws {
		// do nothing
	}
}

extension Folder {
	mutating func runProcessor<T>(
		_ processor: ProcessorFunction<T>,
		on glob: Glob,
		in environment: inout Processor.Environment,
		at path: consuming [String],
		configuration: Configuration
	) throws {
		path.append(self.name)
		guard glob.couldFindMatch(in: copy path) else { return }
		
		if var selfAsT = self as? T {
			try processor(&selfAsT, &environment, configuration)
			self = selfAsT as! Folder
		}
		
		for index in contents.indices {
			try contents[index].runProcessor(
				processor,
				on: glob,
				in: &environment,
				at: path,
				configuration: configuration
			)
		}
	}
}

extension BinaryFile {
	mutating func runProcessor<T>(
		_ processor: ProcessorFunction<T>,
		on glob: Glob,
		in environment: inout Processor.Environment,
		at path: [String],
		configuration: Configuration
	) throws {
		guard glob.matches(path + [name]) else { return }
		
		if var selfAsT = self as? T {
			try processor(&selfAsT, &environment, configuration)
			self = selfAsT as! BinaryFile
		}
	}
}

extension MAR.Unpacked {
	mutating func runProcessor<T>(
		_ processor: ProcessorFunction<T>,
		on glob: Glob,
		in environment: inout Processor.Environment,
		at path: consuming [String],
		configuration: Configuration
	) throws {
		path.append(self.name)
		guard glob.couldFindMatch(in: copy path) else { return }
		
		if var selfAsT = self as? T {
			try processor(&selfAsT, &environment, configuration)
			self = selfAsT as! MAR.Unpacked
		}
		
		if files.count == 1 {
			try files[0].content.runProcessor(
				processor,
				in: &environment,
				configuration: configuration
			)
		} else {
			for index in files.indices {
				let mcmPath = path + [String(index).padded(toLength: 4, with: "0")]
				guard glob.matches(mcmPath) else { continue }
				
				try files[index].content.runProcessor(
					processor,
					in: &environment,
					configuration: configuration
				)
			}
		}
	}
}

extension MAR.Packed {
	mutating func runProcessor<T>(
		_ processor: ProcessorFunction<T>,
		on glob: Glob,
		in environment: inout Processor.Environment,
		at path: [String],
		configuration: Configuration
	) throws {
		// do nothing
	}
}

extension ProprietaryFile {
	mutating func runProcessor<T>(
		_ processor: ProcessorFunction<T>,
		on glob: Glob,
		in environment: inout Processor.Environment,
		at path: [String],
		configuration: Configuration
	) throws {
		guard glob.matches(path + [name]) else { return }
		
		try data.runProcessor(
			processor,
			in: &environment,
			configuration: configuration
		)
	}
}

extension ProprietaryFileData {
	mutating func runProcessor<T>(
		_ processor: ProcessorFunction<T>,
		in environment: inout Processor.Environment,
		configuration: Configuration
	) throws {
		if var selfAsT = self as? T {
			try processor(&selfAsT, &environment, configuration)
			self = selfAsT as! Self
		}
	}
}
