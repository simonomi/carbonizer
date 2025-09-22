func dtxRipperF(
	_ dtx: inout DTX.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	guard environment.text == nil else {
		throw TooManyTextFiles()
	}
	environment.text = dtx.strings
}

struct TooManyTextFiles: Error, CustomStringConvertible {
	var description: String {
		"somehow there are more than one text file"
	}
}
