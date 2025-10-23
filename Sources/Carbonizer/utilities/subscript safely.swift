extension RandomAccessCollection {
	subscript(safely index: Index) -> Element? {
		if indices.contains(index) {
			self[index]
		} else {
			nil
		}
	}
}
