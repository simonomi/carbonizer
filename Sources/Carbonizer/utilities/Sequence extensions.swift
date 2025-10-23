extension Sequence {
	func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
		sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
	}
	
	func compactMap<T>(as type: T.Type) -> [T] {
		compactMap { $0 as? T }
	}
	
	func interspersed(with element: Element) -> JoinedSequence<[[Element]]> {
		map { [$0] }.joined(separator: [element])
	}
}

extension Sequence where Element: Sequence {
	func recursiveMap<T>(_ transform: @escaping (Element.Element) throws -> T) rethrows -> [[T]] {
		try map { try $0.map(transform) }
	}
}

extension Sequence where Element: AdditiveArithmetic {
	func sum() -> Element {
		reduce(.zero, +)
	}
}
