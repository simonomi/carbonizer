enum PackedStatus {
	case unknown, packed, unpacked, contradictory
	
	var wasPacked: Bool? {
		switch self {
			case .packed: true
			case .unpacked: false
			default: nil
		}
	}
	
	func combined(with newValue: Self) -> Self {
		switch (self, newValue) {
			case (.unknown, let other), (let other, .unknown): other
			case (.packed, .packed): .packed
			case (.unpacked, .unpacked): .unpacked
			default: .contradictory
		}
	}
}
