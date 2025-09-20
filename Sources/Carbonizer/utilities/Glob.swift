public struct Glob: Decodable, Sendable {
	var components: [Component]
	
	enum Component {
		case exactly(Substring)
		case wildcard(WildcardPattern)
		case recursiveWildcard
		
		struct WildcardPattern {
			var prefix: Substring?
			var suffix: Substring?
			
			init(_ raw: Substring) throws(InvalidGlobError) {
				guard raw.count(where: { $0 == "*" }) == 1 else {
					throw .tooManyWildcards(in: raw)
				}
				
				let wildcardIndex = raw.firstIndex(of: "*")!
				
				switch wildcardIndex {
					case raw.startIndex:
						suffix = raw.dropFirst()
					case raw.index(before: raw.endIndex):
						prefix = raw.dropLast()
					default:
						prefix = raw[...wildcardIndex]
						suffix = raw[raw.index(after: wildcardIndex)...]
				}
			}
		}
		
		init(_ raw: Substring) throws(InvalidGlobError) {
			self = if raw == "**" {
				.recursiveWildcard
			} else if raw.contains("**") {
				throw .tooManyRecursiveWildcards(in: raw)
			} else if raw.contains("*") {
				.wildcard(try WildcardPattern(raw))
			} else {
				.exactly(raw)
			}
		}
	}
	
	enum InvalidGlobError: Error, CustomStringConvertible {
		case tooManyWildcards(in: Substring)
		case tooManyRecursiveWildcards(in: Substring)
		
		var description: String {
			switch self {
				case .tooManyWildcards(let rawGlobComponent):
					"too many uses of wildcard ('\(.cyan)*\(.normal)') in glob: '\(.red)\(rawGlobComponent)\(.normal)'"
				case .tooManyRecursiveWildcards(let rawGlobComponent):
					"invalid use of recursive wildcard ('\(.cyan)**\(.normal)') in glob: '\(.red)\(rawGlobComponent)\(.normal)`"
			}
		}
	}
	
	init(components: some Sequence<Component>) {
		self.components = Array(components)
	}
	
	init(raw: String) throws {
		components = try raw.split(separator: "/").map(Component.init)
	}
	
	public init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		let raw = try container.decode(String.self)
		self = try Self(raw: raw)
	}
}

extension Glob {
	consuming func matches(_ path: consuming [String]) -> Bool {
		while true {
			switch (components.first, path.first) {
				case (nil, nil):
					return true
				case (_?, nil), (nil, _?):
					return false
				case (let component?, let pathComponent?):
					switch component {
						case .exactly(let expectedPathComponent):
							if pathComponent == expectedPathComponent {
								components.removeFirst()
								path.removeFirst()
							} else {
								return false
							}
						case .wildcard(let pattern):
							if pattern.matches(pathComponent) {
								components.removeFirst()
								path.removeFirst()
							} else {
								return false
							}
						case .recursiveWildcard:
							let remainingComponents = components.dropFirst()
							let remainingGlob = Glob(components: remainingComponents)
							
							let pathSuffixes = (path.startIndex...path.endIndex)
								.map { path[$0...] }
								.map(Array.init)
							
							return pathSuffixes.contains(where: remainingGlob.matches)
					}
			}
		}
	}
	
	// this version works for folders, to allow short-circuiting
	consuming func couldFindMatch(in path: consuming [String]) -> Bool {
		while true {
			switch (components.first, path.first) {
				case (nil, nil), (_?, nil), (.recursiveWildcard, _):
					return true
				case (nil, _?):
					return false
				case (.exactly(let expectedPathComponent), let pathComponent?):
					if pathComponent == expectedPathComponent {
						components.removeFirst()
						path.removeFirst()
					} else {
						return false
					}
				case (.wildcard(let pattern), let pathComponent?):
					if pattern.matches(pathComponent) {
						components.removeFirst()
						path.removeFirst()
					} else {
						return false
					}
			}
		}
	}
}

extension Glob.Component.WildcardPattern {
	func matches(_ pathComponent: String?) -> Bool {
		guard let pathComponent else { return false }
		
		if let prefix {
			guard pathComponent.hasPrefix(prefix) else { return false }
		}
		
		if let suffix {
			guard pathComponent.hasSuffix(suffix) else { return false }
		}
		
		return true
	}
}

extension Glob: ExpressibleByStringLiteral {
	public init(stringLiteral: String) {
		try! self.init(raw: stringLiteral)
	}
}
