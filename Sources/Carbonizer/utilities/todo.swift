func todo(
	_ message: String? = nil,
	function: String = #function,
	file: StaticString = #file,
	line: UInt = #line
) -> Never {
	if let message {
		fatalError("TODO: \(function): \(message)", file: file, line: line)
	} else {
		fatalError("TODO: \(function)", file: file, line: line)
	}
}
