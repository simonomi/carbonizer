extension SpriteAnimation {
	struct Image {
		var isVisible: Bool = false
		var palette: UInt16 = 0
		var bitmap: UInt16 = 0
		var position: Point<Int16> = .zero
//		var transform: (Int, Int, Int, Int)
	}
}

extension SpriteAnimation.Image: CustomStringConvertible {
	var description: String {
		"[\(isVisible ? "x" : " ")] \(palette) \(bitmap) at \(position)"
	}
}

extension [SpriteAnimation.Image] {
	subscript(fitting index: UInt8) -> SpriteAnimation.Image {
		get {
			if indices.contains(Int(index)) {
				self[Int(index)]
			} else {
				SpriteAnimation.Image()
			}
		}
		set {
			if indices.contains(Int(index)) {
				self[Int(index)] = newValue
			} else {
				for _ in 0...(Int(index) - count) {
					append(SpriteAnimation.Image())
					self[Int(index)] = newValue
				}
			}
		}
	}
}
