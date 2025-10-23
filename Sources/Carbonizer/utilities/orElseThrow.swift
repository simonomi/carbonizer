extension Optional {
	func orElseThrow(_ error: @autoclosure () -> some Error) throws -> Wrapped {
		if let self {
			self
		} else {
			throw error()
		}
	}
}
