//
//  PostProcessor.swift
//
//
//  Created by simon pellerin on 2023-06-22.
//

typealias PostProcessor = (_ file: File, _ parent: Folder) -> [FSFile]

extension Folder {
	func postProcessed(with postProcessor: PostProcessor) -> Folder {
		Folder(
			named: name,
			children: children.flatMap {
				switch $0 {
					case .folder(let folder):
						return [FSFile.folder(folder.postProcessed(with: postProcessor))]
					case .file(let file, _):
						return postProcessor(file, self)
				}
			}
		)
	}
}

extension NDSFile {
	func postProcessed(with postProcessor: PostProcessor) -> NDSFile {
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
			contents: contents.map {
				if case .folder(let folder) = $0 {
					return .folder(folder.postProcessed(with: postProcessor))
				} else {
					return $0
				}
			}
		)
	}
}

extension FSFile {
	func postProcessed(with postProcessor: PostProcessor) -> FSFile {
		if case .folder(let folder) = self {
			return .folder(folder.postProcessed(with: postProcessor))
		} else if case .file(.ndsFile(let ndsFile), let metadata) = self {
			return .file(.ndsFile(ndsFile.postProcessed(with: postProcessor)), metadata)
		} else {
			return self
		}
	}
}
