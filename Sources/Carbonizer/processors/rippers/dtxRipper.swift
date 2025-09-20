func dtxRipperF(
	_ dtx: inout DTX.Unpacked,
	in environment: inout Processor.Environment
) {
	environment.text = dtx.strings
}
