extension Array {
	subscript(x x: Index, y y: Index, width width: Index) -> Element {
		get { self[x + y * width] }
		set { self[x + y * width] = newValue }
	}
}
