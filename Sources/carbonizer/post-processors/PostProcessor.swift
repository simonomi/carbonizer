typealias PostProcessor = (consuming ProprietaryFile, _ parent: Folder) throws -> [any FileSystemObject]

//extension File {
//	consuming func postProcessed(with postProcessor: PostProcessor) rethrows -> Self {
//		if var nds = data as? NDS {
//			nds.contents = try nds.contents.map {
//				try $0.postProcessed(with: postProcessor)
//			}
//			data = nds
//		}
//		return self
//	}
//}
//
//extension Folder {
//	consuming func postProcessed(with postProcessor: PostProcessor) rethrows -> Self {
//		contents = try contents.flatMap {
//			if let file = $0 as? File {
//				try postProcessor(file, self)
//			} else if let folder = $0 as? Folder {
//				[try folder.postProcessed(with: postProcessor)]
//			} else {
//				fatalError("unreachable")
//			}
//		}
//		return self
//	}
//}
