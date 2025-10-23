extension Set {
	consuming func inserting(_ element: Element) -> Self {
		insert(element)
		return self
	}
}
