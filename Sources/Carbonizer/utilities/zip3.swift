func zip<S: Sequence, T: Sequence, U: Sequence>(
	_ first: S,
	_ second: T,
	_ third: U
) -> [(S.Element, T.Element, U.Element)] {
	zip(first, zip(second, third))
		.map { ($0, $1.0, $1.1) }
}
