func sIfPlural(_ number: some BinaryInteger) -> StaticString {
	if number == 1 {
		""
	} else {
		"s"
	}
}
