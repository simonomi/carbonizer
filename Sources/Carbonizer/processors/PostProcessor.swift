typealias ProcessorFunction<T> = (inout T, _ environment: inout Processor.Environment) throws -> Void

extension NDS.Unpacked {
	mutating func runProcessor<T>(
		_ processor: ProcessorFunction<T>,
		on glob: Glob,
		in environment: inout Processor.Environment,
		at path: [String]
	) throws {
		for index in contents.indices {
			try contents[index].runProcessor(
				processor,
				on: glob,
				in: &environment,
				at: path
			)
		}
	}
}

extension NDS.Packed {
	mutating func runProcessor<T>(
		_ processor: ProcessorFunction<T>,
		on glob: Glob,
		in environment: inout Processor.Environment,
		at path: [String]
	) throws {
		// do nothing
	}
}

extension Folder {
	mutating func runProcessor<T>(
		_ processor: ProcessorFunction<T>,
		on glob: Glob,
		in environment: inout Processor.Environment,
		at path: consuming [String]
	) throws {
		path.append(self.name)
		guard glob.couldFindMatch(in: copy path) else { return }
		
		if var selfAsT = self as? T {
			try processor(&selfAsT, &environment)
			self = selfAsT as! Folder
		}
		
		for index in contents.indices {
			try contents[index].runProcessor(
				processor,
				on: glob,
				in: &environment,
				at: path
			)
		}
	}
}

extension BinaryFile {
	mutating func runProcessor<T>(
		_ processor: ProcessorFunction<T>,
		on glob: Glob,
		in environment: inout Processor.Environment,
		at path: [String]
	) throws {
		guard glob.matches(path + [name]) else { return }
		
		if var selfAsT = self as? T {
			try processor(&selfAsT, &environment)
			self = selfAsT as! BinaryFile
		}
	}
}

extension MAR.Unpacked {
	mutating func runProcessor<T>(
		_ processor: ProcessorFunction<T>,
		on glob: Glob,
		in environment: inout Processor.Environment,
		at path: consuming [String]
	) throws {
		path.append(self.name)
		guard glob.couldFindMatch(in: copy path) else { return }
		
		if var selfAsT = self as? T {
			try processor(&selfAsT, &environment)
			self = selfAsT as! MAR.Unpacked
		}
		
		if files.count == 1 {
			try files[0].content.runProcessor(processor, in: &environment)
		} else {
			for index in files.indices {
				let mcmPath = path + [String(index).padded(toLength: 4, with: "0")]
				guard glob.matches(mcmPath) else { continue }
				
				try files[index].content.runProcessor(processor, in: &environment)
			}
		}
	}
}

extension MAR.Packed {
	mutating func runProcessor<T>(
		_ processor: ProcessorFunction<T>,
		on glob: Glob,
		in environment: inout Processor.Environment,
		at path: [String]
	) throws {
		// do nothing
	}
}

extension ProprietaryFile {
	mutating func runProcessor<T>(
		_ processor: ProcessorFunction<T>,
		on glob: Glob,
		in environment: inout Processor.Environment,
		at path: [String]
	) throws {
		guard glob.matches(path + [name]) else { return }
		
		try data.runProcessor(processor, in: &environment)
	}
}

extension ProprietaryFileData {
	mutating func runProcessor<T>(
		_ processor: ProcessorFunction<T>,
		in environment: inout Processor.Environment
	) throws {
		if var selfAsT = self as? T {
			try processor(&selfAsT, &environment)
			self = selfAsT as! Self
		}
	}
}
