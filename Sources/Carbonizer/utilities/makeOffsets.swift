func makeOffsets(
	start: UInt32,
	sizes: some Collection<UInt32>,
	alignedTo alignment: UInt32 = 1
) -> [UInt32] {
	if sizes.isEmpty {
		[]
	} else {
		sizes
			.dropLast()
			.reduce(into: [start]) { offsets, size in
				offsets.append((offsets.last! + size).roundedUpToTheNearest(alignment))
			}
	}
}
