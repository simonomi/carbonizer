import Testing

@testable import CarbonizerCLI

@Test
func defaultConfigurationIsValid() throws {
	_ = try CLIConfiguration(
		decoding: CLIConfiguration.defaultConfigurationString
	)
}
