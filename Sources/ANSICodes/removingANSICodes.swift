public extension String {
	func removingANSICodes() -> Self {
		// this only removes the codes carbonizer uses
		replacing(/\x{001B}\[[0-9;]+[mKG]/, with: "")
	}
}
