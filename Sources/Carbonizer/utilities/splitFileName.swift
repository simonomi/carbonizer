func splitFileName(_ name: String) -> (name: String, fileExtensions: String) {
	let split = name.split(separator: ".", maxSplits: 1)
	if split.count == 2 {
		return (String(split[0]), String(split[1]))
	} else {
		return (name, "")
	}
}
