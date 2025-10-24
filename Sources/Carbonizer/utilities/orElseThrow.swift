extension Optional {
	func orElseThrow<E: Error>(_ error: @autoclosure () -> E) throws(E) -> Wrapped {
		if let self {
			self
		} else {
			throw error()
		}
	}
}
