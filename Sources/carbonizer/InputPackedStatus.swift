enum InputPackedStatus {
	case unknown, packed, unpacked, contradictory
	
	var wasPacked: Bool? {
		switch self {
			case .packed: true
			case .unpacked: false
			default: nil
		}
	}
	
	func combined(with newValue: Self) -> Self {
		if self == .unknown || self == newValue {
			newValue
		} else {
			.contradictory
		}
	}
}
