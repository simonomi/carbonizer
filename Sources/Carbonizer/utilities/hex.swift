func hex<T: BinaryInteger & SignedNumeric>(_ value: T) -> String {
	if value < 0 {
		"-0x\(String(-value, radix: 16))"
	} else {
		"0x\(String(value, radix: 16))"
	}
}
