import Foundation

#if os(macOS)
typealias EventHandler = @MainActor (URL) async throws -> Void

struct PathMonitor {
	var sources: [any DispatchSourceFileSystemObject]
}

@discardableResult
func monitorFiles(
	in path: URL,
	with eventHandler: sending @escaping @isolated(any) EventHandler
) throws -> PathMonitor {
	guard try path.isDirectory() else {
		fatalError("cannot monitor file")
	}
	
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
		
		Task { [eventHandler] in
			do {
				try await Task.sleep(for: .seconds(0.1)) // give sime time for any editing to finish
				try await eventHandler(latestModifiedPath)
			} catch {
				print(error)
			}
		}
	}
	
	source.setEventHandler(handler: handler)
	
	source.activate()
	
	let subSources = try path
		.contents()
		.filter { try $0.isDirectory() }
		.flatMap { try monitorFiles(in: $0, with: eventHandler).sources }
	
	return PathMonitor(sources: [source] + subSources)
}
#endif
