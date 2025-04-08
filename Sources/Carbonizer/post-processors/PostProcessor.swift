typealias PostProcessor = (consuming any FileSystemObject, _ parent: Folder) throws -> [any FileSystemObject]

extension FileSystemObject {
	consuming func postProcessed(with postProcessor: PostProcessor) rethrows -> Self {
		fatalError("shouldnt be called on \(Self.self)")
	}
}

extension NDS {
	consuming func postProcessed(with postProcessor: PostProcessor) rethrows -> Self {
		contents = try contents.map { try $0.postProcessed(with: postProcessor) }
		return self
	}
}

extension Folder {
	consuming func postProcessed(with postProcessor: PostProcessor) rethrows -> Self {
		contents = try contents.flatMap {
			switch $0 {
				case let nds as NDS:
					[try nds.postProcessed(with: postProcessor)]
				case let folder as Folder:
					[try folder.postProcessed(with: postProcessor)]
				case let other:
					try postProcessor(other, self)
			}
		}
		return self
	}
}
