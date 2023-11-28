//
//  PostProcessor.swift
//
//
//  Created by simon pellerin on 2023-06-22.
//

typealias PostProcessor = (_ file: File, _ parent: Folder) throws -> [FSFile]

extension Folder {
	func postProcessed(with postProcessor: PostProcessor) rethrows -> Folder {
		Folder(
			named: name,
			children: try children.flatMap {
				switch $0 {
					case .folder(let folder):
						return [FSFile.folder(try folder.postProcessed(with: postProcessor))]
					case .file(let file, _):
						return try postProcessor(file, self)
				}
			}
		)
	}
}

extension NDSFile {
	func postProcessed(with postProcessor: PostProcessor) rethrows -> NDSFile {
		NDSFile(
			name: name,
			header: header,
			arm9: arm9,
			arm9OverlayTable: arm9OverlayTable,
			arm9Overlays: arm9Overlays,
			arm7: arm7,
			arm7OverlayTable: arm7OverlayTable,
			arm7Overlays: arm7Overlays,
			iconBanner: iconBanner,
			contents: try contents.map {
				if case .folder(let folder) = $0 {
					return .folder(try folder.postProcessed(with: postProcessor))
				} else {
					return $0
				}
			}
		)
	}
}

extension FSFile {
	func postProcessed(with postProcessor: PostProcessor) rethrows -> FSFile {
		if case .folder(let folder) = self {
			return .folder(try folder.postProcessed(with: postProcessor))
		} else if case .file(.ndsFile(let ndsFile), let metadata) = self {
			return .file(.ndsFile(try ndsFile.postProcessed(with: postProcessor)), metadata)
		} else {
			return self
		}
	}
}
