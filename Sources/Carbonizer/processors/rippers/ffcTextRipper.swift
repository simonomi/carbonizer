func ffcTextRipperF(
	_ dtx: inout DTX.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	if environment.ffcText == nil {
		environment.ffcText = [:]
	}
	
	environment.ffcText![path.last!] = dtx.strings
}
