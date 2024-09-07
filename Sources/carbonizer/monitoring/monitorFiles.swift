import Foundation

#if os(macOS)
typealias EventHandler = (URL) throws -> Void

struct PathMonitor {
	var sources: [any DispatchSourceFileSystemObject]
	
	func cancel() {
		for source in sources {
			source.cancel()
		}
	}
}

func monitorFiles(in path: URL, with eventHandler: @escaping EventHandler) throws -> PathMonitor {
	let fileDescriptor = open(path.path(percentEncoded: false), O_EVTONLY)
	
	let source = DispatchSource.makeFileSystemObjectSource(
		fileDescriptor: fileDescriptor,
		eventMask: .all
	)
	
	let handler = DispatchWorkItem {
		let (latestModifiedPath, lastDate) = try! path
			.contents()
			.compactMap { path in
				(try? path.getModificationDate()).map { (path, $0) }
			}
			.max { $0.1 < $1.1 }!
		
		// last modified more than a second ago
		if -lastDate.timeIntervalSinceNow > 1 { return }
		
//		print(latestModifiedPath as Any, lastDate)
		
		do {
			try eventHandler(latestModifiedPath)
		} catch {
			print(error)
		}
	}
	
	source.setEventHandler(handler: handler)
	
	source.activate()
	
	let subSources = try path
		.contents()
		.filter({ try $0.type() == .folder })
		.flatMap { try monitorFiles(in: $0, with: eventHandler).sources }
	
	return PathMonitor(sources: [source] + subSources)
}
#endif
