extension SpriteAnimation {
	struct Point<T: BinaryInteger & Sendable>: AdditiveArithmetic {
		var x: T
		var y: T
		
		static func + (lhs: Point<T>, rhs: Point<T>) -> Point<T> {
			Point(
				x: lhs.x + rhs.x,
				y: lhs.y + rhs.y
			)
		}
		
		static func - (lhs: Point<T>, rhs: Point<T>) -> Point<T> {
			Point(
				x: lhs.x - rhs.x,
				y: lhs.y - rhs.y
			)
		}
		
		static var zero: Self { Self(x: 0, y: 0) }
	}
}

extension SpriteAnimation.Point: CustomStringConvertible {
	var description: String {
		"(\(x), \(y))"
	}
}
