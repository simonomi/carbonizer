import Testing
import Foundation

@testable import carbonizer

@Test
func defaultConfiguration() throws {
	_ = try CarbonizerConfiguration(
		decoding: CarbonizerConfiguration.defaultConfigurationString
	)
}
