typealias PostProcessor = (consuming ProprietaryFile, _ parent: Folder) throws -> [any FileSystemObject]

extension Folder {
	consuming func postProcessed(with postProcessor: PostProcessor) rethrows -> Self {
		contents = try contents.map {
			try $0.postProcessed(with: postProcessor)
		}
		return self
	}
}

extension MAR {
	consuming func postProcessed(with postProcessor: PostProcessor) rethrows -> Self {
		fatalError()
	}
}

extension PackedMAR {
	consuming func postProcessed(with postProcessor: PostProcessor) rethrows -> Self {
		fatalError()
	}
}

extension NDS {
	consuming func postProcessed(with postProcessor: PostProcessor) rethrows -> Self {
		fatalError()
	}
}

extension PackedNDS {
	consuming func postProcessed(with postProcessor: PostProcessor) rethrows -> Self {
		fatalError()
	}
}

extension BinaryFile {
	consuming func postProcessed(with postProcessor: PostProcessor) rethrows -> Self {
		fatalError()
	}
}

extension ProprietaryFile {
	consuming func postProcessed(with postProcessor: PostProcessor) rethrows -> Self {
		fatalError()
	}
}
