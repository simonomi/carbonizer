func textRipperF(
	_ dtx: inout DTX.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	if environment.text == nil {
		environment.text = [:]
	}
	
	environment.text![path.last!] = dtx.strings
}
